return {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        -- must be a predefined style name; inline YAML is rejected outright and
        -- clangd silently drops back to plain LLVM (2-space) indentation.
        -- Indent width lives in ~/.clang-format instead.
        "--fallback-style=LLVM",
    },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    root_markers = {
        ".clangd",
        "compile_commands.json",
        "compile_flags.txt",
        "CMakeLists.txt",
        ".git",
    },
    init_options = {
        usePlaceholders = true,
        completeUnimported = true,
        clangdFileStatus = true,
    },
}
