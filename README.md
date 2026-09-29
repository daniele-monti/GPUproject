# Bitsort algorithm implemented with cuda c
This project deals with the implementation of the bitsort algorithm using cuda c. The performance of said algorithm is then compared to the performance of the two classic sorting algortihms mergesort and quicksort.

The system configuration used to run the benchmarks is as follows:
- OS:  Ubuntu 24.04.5 LTS
- CPU: AMD Ryzen 7 9700X (16) @ 5.581GHz
- GPU: NVIDIA GeForce RTX 4060

### Notes on compilation
Because .cu files are treated as C++ code, nvcc looks for functions with C++ mangled names.
However, I was using .c files, which were being compiled as standard C, which does not mangle names, so the linker couldn't find the function names. I opted to then use .cpp files instead, even if the code does not use any c++ features.


## Bitmerge
The bitmerge procedure is the fundamental building block for the bitsort algorithm. It accepts a bitonic sequence in input and it sorts it in an iterative fashion. The parallel algorithm is obtained unrolling the recursion of the following (n is the length of the input array):
```code
bitMerge(A):
    minmax(A)
    if (|A| > 2):
        bitMerge(A[:n/2])
        bitMerge(A[n/2:]) 
``` 
In the `minmax` procedure, n/2 threads are used: each thread compares two elements of the array that are n/2 positions apart and if the one on the left is greater then the one on the rigth it swaps them. This creates 2 bitonic sequences (because the input array is bitonic), one in the first half of the array and the other in the second half, such that each element in the first half is less or equal to each element of the second half. The recursive call to bitMerge on each of these halves can be unrolled and parallelized: now we have n/4 threads operating the minmax procedure on the first half and n/4 threads operating on the second half; in total, we are still using n/2 threads. After this operation is done, we can synchronize the threads before unrolling and parallelizing the recursive calls that each of the halves do on *their* halves.
This process goes on until the size of the halves is 2: here the minmax procedure results in sorting the array.  


## Bitsort
The bisort algorithm consists in iteratively applying the bitmerge procedure in parallel on larger and larger subslices of the original array to be sorted, with the caveat that the slices on even positions (the first slice has position 0) must be sorted in ascending order and the ones in odd positions must be sorted in descending order (or viceversa), in order to have a bitonic sequence for the following iteration. We start with slices of size 2 and at each iteration the size of the slices doubles.

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


## Performance analysis
I chose to track the time used by each algorithm as a client who doesn't know whether bitsort in implemented on the gpu or the cpu, in order to be as fair as possible. This means the tracked time includes the time used to complete the copy of the data to and from the device. Data for quicksort is missing for inputs larger than 2^26 because it took about 30 minutes to complete a quicksort on one (1) input of size 2^27.

For inputs of 2^10 and smaller, the overhead of involving the GPU is greater than the benefits, leading to bitsort taking longer than the other options. From inputs of size 2^11 and larger, bitsort is consistently faster.

The speedup compared to mergesort accelerates up to about 38 for inputs of 2^22 elements, then drops to a somewhat stable 10 for inputs larger than that.

The speedup compared to quicksort is lower than the speedup compared to mergesort up to 2^18, but then it explodes almost exponentially afterwards.

One thing of note is that for input of size 2^23 bitsort takes on average 47.13 ms, which is quite the step up from the time it took for inputs of size 2^22, which is 8.45. From inputsof size 2^24 and onwards, the time roughly doubles compared to inputs of half the size. I am not sure why this is the case, i suspect some kind of hardware limits are met with inputs of size 2^23 which act as bottlenecks. 
