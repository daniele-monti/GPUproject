#ifndef _COMMON_H
#define _COMMON_H
#include <stdbool.h>
#include <stdio.h>

typedef unsigned int uint;

// my gpu has a max number of threads for sm of 1536, i.e. 3 blocks of 512 threads
#define NUM_THREADS 512U
// each thread will be accessing 2 separate memory location 
#define SMEM_SIZE NUM_THREADS*2

#define CHECK(call)                                                            \
{                                                                              \
    const cudaError_t error = call;                                            \
    if (error != cudaSuccess)                                                  \
    {                                                                          \
        fprintf(stderr, "Error: %s:%d, ", __FILE__, __LINE__);                 \
        fprintf(stderr, "code: %d, reason: %s\n", error,                       \
                cudaGetErrorString(error));                                    \
    }                                                                          \
}

#endif
