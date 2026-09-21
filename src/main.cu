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

#include "sort.h"
#include "utils.h"
#include "types.h"
#include <stdio.h>
#include <time.h>
#include <stdlib.h>

#define N 500

// kernel cumsum
__global__ void cum_sum(int *a, int *b) {
    int idx = threadIdx.x;
    int sum = 0;
    for (int j = 0; j < idx; j++) {
        sum += a[j]; 
    }
    b[idx] = sum;
}

// Main function
int main() {
    int *a, *b;
    int *dev_a, *dev_b;
    int nBytes = N * sizeof(int);

    a = (int *) malloc(nBytes);
    b = (int *) malloc(nBytes);

    for (int i = 0; i < N; i++) {
        a[i] = 1;
        b[i] = 0;
    }

    CHECK(cudaMalloc((void **) &dev_a, nBytes));
    CHECK(cudaMalloc((void **) &dev_b, nBytes));

    CHECK(cudaMemcpy(dev_a, a, nBytes, cudaMemcpyHostToDevice));
    cudaMemcpy(dev_b, b, nBytes, cudaMemcpyHostToDevice);

    cum_sum<<<1, N>>>(dev_a, dev_b);
    
    CHECK(cudaMemcpy(b, dev_b, nBytes, cudaMemcpyDeviceToHost));
    CHECK(cudaDeviceSynchronize());

    printf("Position 4: %d\n", b[4]);
    printf("Position 0: %d\n", b[0]);
    printf("Position 10: %d\n", b[10]);
    printf("Position 3: %d\n", b[3]);
    printf("Position 20: %d\n", b[20]);
    printf("Position 200: %d\n", b[200]);

    int n = 10;
    int min = 1;
    int max = 100;
    
    int* test_array = random_integers(n, min, max, time(NULL));
    if (test_array != NULL) {
        printf("Array of %d random numbers between %d and %d:\n", n, min, max);
        print_array(test_array, n);
        merge_sort(test_array, n);
        printf("Mergesort: ");
        print_array(test_array, n);
    }

    test_array = random_integers(n, min, max, time(NULL)+12);
    if (test_array != NULL) {
        printf("Array of %d random numbers between %d and %d:\n", n, min, max);
        print_array(test_array, n);
        quick_sort(test_array, n);
        printf("Quicksort: ");
        print_array(test_array, n);
        free(test_array);
    }
  return 0;
}
