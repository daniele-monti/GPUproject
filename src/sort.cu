#include "sort.h"
#include "common.h"
#include <stdlib.h>
#include <memory.h>

/*
__device__ __host__ inline void compare_swap(int* value_a, int* value_b) {
    int temp;
    if (*value_a < *value_b ) {
        temp = *value_a;

    }
}
*/

// quicksort
uint partition(int* array, uint start, uint end) {
    int pivot = array[start];
    uint left = start;
    uint right = end;
    int temp = 0;
    while (left < right) {
        do right--; while (array[right] > pivot);
        do left++; while (left < right && array[left] <= pivot);
        if (left < right) {
            temp = array[left];
            array[left] = array[right];
            array[right] = temp;
        }
    }
    array[start] = array[right];
    array[right] = pivot;
    return right;
}

void _quick_sort(int* array, uint start, uint end) {
    while (end - start > 1) {
        uint pivot = partition(array, start, end);
        if (pivot - start < end - pivot) {
            _quick_sort(array, start, pivot);
            start = pivot + 1;
        } else {
            _quick_sort(array, pivot+1, end);
            end = pivot;
        }
    }
}

void quick_sort(int* array, uint length) {
    _quick_sort(array, 0, length);
}



// mergesort
void merge(int* array, int* helper, uint start, uint middle, uint end) {
    uint i = start;
    uint j = middle;
    uint k = 0;
    while (i < middle && j < end) {
        if (array[i] <= array[j]) helper[k] = array[i++];
        else helper[k] = array[j++];
        k++;
    }
    if (i < middle) {
        for (uint idx = i; idx < middle; idx++) helper[k++] = array[idx]; 
    } else {
        for (uint idx = j; idx < end; idx++) helper[k++] = array[idx];
    }
    for (uint idx = 0; idx < k; idx++) array[start + idx] = helper[idx];
}

void _merge_sort(int* array, int* helper, uint start, uint end) {
    if (end - start > 1) {
        uint middle = (start + end) / 2;
        _merge_sort(array, helper, start, middle);
        _merge_sort(array, helper, middle, end);
        merge(array, helper, start, middle, end); 
    }
}

void merge_sort(int* array, uint length) {
    int* helper = (int*)malloc(sizeof(int) * length);
    _merge_sort(array, helper, 0, length);
    free(helper);
}



// only works for array whose length is a power of 2
__global__ void bitonic_merge(int* d_in, uint length) {
    uint tid = threadIdx.x;
    uint idx = blockDim.x * blockIdx.x + tid;

    for (uint stride = length / 2; stride > 0; stride >>= 1) {
        // equivalent: pos = 2*idx - (idx & (stride - 1))
        uint pos = 2 * idx - (idx % stride);
        int left = d_in[pos];
        int right = d_in[pos + stride];
        if (left > right) {
            int temp = left;
            d_in[pos] = d_in[pos + stride];
            d_in[pos + stride] = temp;
        }
        __syncthreads();
    }
    return;
}

// only works for array whose length is a power of 2
__global__ void bitonic_sort(int* d_in, uint length) {
    uint tid = threadIdx.x;
    uint idx = blockDim.x * blockIdx.x + tid;
    bool ascending;

    for (uint size = 2; size < length; size <<= 1) {
        // bitmerge: we have to select which threads will be doing sorting in ascending
        // order and which ones will be doing it in descending order
        ascending = !(idx & (size / 2));
        for (uint stride = size / 2; stride > 0; stride >>= 1) {
            uint pos = 2 * idx - (idx % stride);
            int left = d_in[pos];
            int right = d_in[pos + stride];
            if (
                ( (left > right) &&  ascending ) ||
                ( (left < right) && !ascending )
            ) {
                int temp = left;
                d_in[pos] = d_in[pos + stride];
                d_in[pos + stride] = temp;
            }
        }
        __syncthreads();
    }
    // last bitmerge, we default to ascending order
    for (uint stride = length / 2; stride > 0; stride >>= 1) {
        uint pos = 2 * idx - (idx % stride); // equivalent: 2*idx - (idx & (stride - 1))
        int left = d_in[pos];
        int right = d_in[pos + stride];
        if (left > right) {
            int temp = left;
            d_in[pos] = d_in[pos + stride];
            d_in[pos + stride] = temp;
        }
        __syncthreads();
    }
    return;
}

void bit_sort(int* array, uint length) {
    int* dev_array;
    size_t bytes = length*sizeof(int);

    cudaMalloc(&dev_array, bytes);
    cudaMemcpy(dev_array, array, bytes, cudaMemcpyHostToDevice);

    uint threads = 512;
    uint blocks = (length + threads - 1) / threads;

    bitonic_sort<<<blocks, threads>>>(dev_array, length);

    cudaMemcpy(array, dev_array, bytes, cudaMemcpyDeviceToHost);

    cudaFree(dev_array);
}
