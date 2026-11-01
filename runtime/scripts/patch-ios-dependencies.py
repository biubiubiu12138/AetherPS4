from pathlib import Path

path = Path("externals/ImGuiFileDialog/ImGuiFileDialog.cpp")
source = path.read_text()
old = r"""                char buffer[PATH_MAX] = {};
                snprintf(buffer, PATH_MAX, "mkdir -p \"%s\"", vName.c_str());
                const int dir_err = std::system(buffer);
                if (dir_err != -1) {
                    res = true;
                }"""
new = """                std::error_code error;
                res = std::filesystem::create_directories(vName, error);
                if (error) {
                    std::cerr << "Directory creation failed: " << error.message() << std::endl;
                }"""
if old not in source:
    raise SystemExit("Pinned ImGuiFileDialog source changed; inspect directory creation before applying patch")
path.write_text(source.replace(old, new))
