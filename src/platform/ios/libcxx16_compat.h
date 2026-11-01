// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#pragma once
#include <__config>
#include <__availability>
// Only these nine floating-point overloads are supplied by our statically linked
// LLVM charconv backport. Keep all other libc++ availability checks enabled.
#ifndef _LIBCPP_AVAILABILITY_TO_CHARS_FLOATING_POINT
#error Inspect the SDK charconv availability annotation before using this backport
#endif
#undef _LIBCPP_AVAILABILITY_TO_CHARS_FLOATING_POINT
#define _LIBCPP_AVAILABILITY_TO_CHARS_FLOATING_POINT
