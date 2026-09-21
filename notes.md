## Compilation
Because .cu files are treated as C++ code, nvcc looks for functions with C++ mangled names.
However, I was using .c files, which were being compiled as standard C, which does not mangle names, so the linker couldn't find the function names.
I opted to then use .cpp files instead, even if the code does not use any c++ features.