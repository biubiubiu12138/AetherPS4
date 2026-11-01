#!/usr/bin/env python3
"""Audit deployment metadata, signatures and backported runtime symbols."""
import argparse
import json
from pathlib import Path
import plistlib
import re
import subprocess


def output(*command):
    return subprocess.check_output(command, stderr=subprocess.PIPE, text=True)


def version(text):
    parts = tuple(int(p) for p in text.split('.'))
    return parts + (0,) * (3 - len(parts))


def audit(app):
    info = plistlib.loads((app / 'Info.plist').read_bytes())
    assert info['MinimumOSVersion'] == '16.2', 'Unexpected app deployment target'
    binary = app / info['CFBundleExecutable']
    assert output('lipo', '-archs', str(binary)).strip() == 'arm64'
    subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)],
                   check=True, capture_output=True)
    signed = subprocess.run(['codesign', '-d', '--entitlements', ':-', str(app)],
                            check=True, capture_output=True)
    entitlements = plistlib.loads(signed.stdout)
    for key in ('get-task-allow',
                'com.apple.developer.kernel.increased-memory-limit'):
        assert entitlements.get(key) is True, 'Missing entitlement: ' + key
    for key in ('dynamic-codesigning', 'com.apple.private.cs.debugger',
                'com.apple.private.skip-library-validation'):
        assert not entitlements.get(key), 'TrollStore-incompatible entitlement: ' + key
    builds = {}
    for path in (binary, app / 'Frameworks/BreakpointJIT.framework/BreakpointJIT',
                 app / 'Frameworks/libvulkan.dylib'):
        data = output('xcrun', 'vtool', '-show-build', str(path))
        assert re.findall(r'platform\s+(\w+)', data) == ['IOS'], str(path)
        minimum = re.search(r'minos\s+([\d.]+)', data).group(1)
        assert version(minimum) <= (16, 2, 0), str(path)
        builds[path.name] = minimum
    undefined = output('nm', '-u', str(binary))
    assert not re.search(r'to_charsEPcS0_[fde]', undefined), \
        'Floating charconv still imports iOS 16.3 runtime functions'
    assert 'os_sync_wait_on_address' not in undefined
    assert 'os_sync_wake_by_address' not in undefined
    return dict(architectures='arm64', minimum='16.2', binaries=builds,
                entitlements=entitlements, signature='verified',
                floating_charconv_imports='none')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('app', type=Path)
    args = parser.parse_args()
    print(json.dumps(audit(args.app), indent=2))
