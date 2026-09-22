## Compilation
Because .cu files are treated as C++ code, nvcc looks for functions with C++ mangled names.
However, I was using .c files, which were being compiled as standard C, which does not mangle names, so the linker couldn't find the function names.
I opted to then use .cpp files instead, even if the code does not use any c++ features.

## Bitsort
The bisort algorithm basically consists in iteratively applying the bitmerge procedure in parallel on larger and larger subslices of the original array to be sorted, with the caveat that the slices on even positions (the first slice has position 0) must be sorted in ascending order and the ones in odd positions must be sorted in descending order (or viceversa). We start with slices of size 2 and at each iteration the size of the slices doubles. Furthermore, in order to apply a bitmerge procedure on an array of size n, only n/2 threads are needed.

<pre>
For example, consider the array [10 2 3 11 9 4 6 7 5 12 8 32 0 1 65 5], which consist of 16 elements and is not bitonic.
The first step of the bitsort algorithm consists will be:    
        [10 2   3 11   9 4   6 7   5 12   8 32   0 1   65 5] 
    tid: 0      1      2     3     4      5      6     7     
        [2 10] [11 3] [4 9] [7 6] [5 12] [32 8] [0 1] [65 5] 
The second step will be:                                     
        [2 10] [11 3] [4 9] [7 6] [5 12] [32 8] [0 1] [65 5] 
    tid: 0   1         2   3       4   5         6    7      
        [2 3 10 11]   [9 7 6 4]   [5 8 12 32]   [65 5 1 0]   
Then the third:                                              
        [2 3 10 11] [9 7 6 4] [5 8 12 32] [65 5 1 0]         
    tid: 0   1   2   3         4   5   6    7                
        [2 3 4 6 7 9 10 11]   [0 1 5 5 8 12 32 65]           
The last step consist in only one bitmerge procedure in ascending (or descending) order which uses all of the 8 (n/2) threads:
        [2 3 4 6 7 9 10 11] [0 1 5 5 8 12 32 65]             
    tid: 0   1   2   3   4   5    6     7                    
        [0 1 2 3 4 5 5 6 7 8 9 10 11 12 32 65]               
</pre>

In order to choose the direction of the sorting the following expression is computed: \
    `tid & (size / 2)`                                                                \
In binary, `(size / 2)` will be, for each iteration:
- 1: ...00001
- 2: ...00010
- 3: ...00100
- 4: ...01000
- etc.

By using the bitwise and operator between this number and the thread ids, we obtain the exact separation we were searching for between threads that must sort in ascending order and threads that must sort in descending order:
- at iteration 1, the sorting order changes every other thread
- at iteration 2, the sorting order changes every other pair of threads
- at iteration 3, the sorting order changes every other group of four threads
- so on and so forth
