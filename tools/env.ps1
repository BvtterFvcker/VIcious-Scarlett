# Portable build environment for C:\VSDEV\Tools (dot-source this from PowerShell: . C:\VSDEV\Tools\env.ps1)
$env:RUSTUP_HOME = 'C:\VSDEV\Tools\rust\rustup'
$env:CARGO_HOME  = 'C:\VSDEV\Tools\rust\cargo'
$env:PATH = "C:\VSDEV\Tools\rust\cargo\bin;$env:PATH"
$env:LIB = 'C:\VSDEV\Tools\xwin\crt\lib\x86_64;C:\VSDEV\Tools\xwin\sdk\lib\um\x86_64;C:\VSDEV\Tools\xwin\sdk\lib\ucrt\x86_64'
$env:CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_LINKER = 'rust-lld'
# C compiler for crates that build C code (cc-rs): clang in MSVC mode against the xwin headers
$env:CC_x86_64_pc_windows_msvc  = 'C:\VSDEV\Tools\llvm-mingw\bin\clang-cl.exe'
$env:CXX_x86_64_pc_windows_msvc = 'C:\VSDEV\Tools\llvm-mingw\bin\clang-cl.exe'
$env:AR_x86_64_pc_windows_msvc  = 'C:\VSDEV\Tools\llvm-mingw\bin\llvm-lib.exe'
$xw = 'C:/VSDEV/Tools/xwin'
$env:CFLAGS_x86_64_pc_windows_msvc = "--driver-mode=cl --target=x86_64-pc-windows-msvc /FIstring.h /imsvc$xw/crt/include /imsvc$xw/sdk/include/ucrt /imsvc$xw/sdk/include/um /imsvc$xw/sdk/include/shared"
$env:CXXFLAGS_x86_64_pc_windows_msvc = $env:CFLAGS_x86_64_pc_windows_msvc
