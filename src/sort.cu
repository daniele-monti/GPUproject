#include "sort.h"
#include "common.h"
#include "utils.h"
#include <stdlib.h>
#include <memory.h>

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

double quick_sort(int* array, uint length) {
    double start = milli_seconds();
    _quick_sort(array, 0, length);
    double stop = milli_seconds();
    return stop - start;
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

double merge_sort(int* array, uint length) {
    double start = milli_seconds();
    int* helper = (int*)malloc(sizeof(int) * length);
    _merge_sort(array, helper, 0, length);
    free(helper);
    double stop = milli_seconds();
    return stop - start;
}



// ############################################################
// all of the following algorithms work only for arrays whose 
// length is a power of 2

// this is for arrays whose length is not greater than SMEM_SIZE
// "output" (side effect, since we are doing in-place sorting) is the sorted array
__global__ void bitonic_sort_small(int* d_in, uint length) {
    uint smem_size = min(SMEM_SIZE, length);
    extern __shared__ int smem[];
    uint idx = blockDim.x * blockIdx.x + threadIdx.x;
    smem[idx + 0]             = d_in[idx + 0];
    smem[idx + smem_size / 2] = d_in[idx + smem_size / 2];
    __syncthreads();
    bool ascending;
    for (uint size = 2; size < length; size <<= 1) {
        // bitmerge: we have to select which threads will be doing sorting in ascending
        // order and which ones will be doing it in descending order
        ascending = !(idx & (size / 2));
        for (uint stride = size / 2; stride > 0; stride >>= 1) {
            uint pos = 2 * idx - (idx % stride);
            int left = smem[pos];
            int right = smem[pos + stride];
            if (
                ( (left > right) &&  ascending ) ||
                ( (left < right) && !ascending )
            ) {
                int temp = left;
                smem[pos] = smem[pos + stride];
                smem[pos + stride] = temp;
            }
            __syncthreads();
        }
    }
    // last bitmerge, we default to ascending order
    for (uint stride = length / 2; stride > 0; stride >>= 1) {
        uint pos = 2 * idx - (idx % stride); // equivalent: 2*idx - (idx & (stride - 1))
        int left = smem[pos];
        int right = smem[pos + stride];
        if (left > right) {
            int temp = left;
            smem[pos] = smem[pos + stride];
            smem[pos + stride] = temp;
        }
        __syncthreads();
    }
    d_in[idx + 0]             = smem[idx + 0];
    d_in[idx + smem_size / 2] = smem[idx + smem_size / 2];
}


// this is for arrays whose length is greater than SMEM_SIZE (i.e. arrays that require more than 1 block)
// we are dividing the input array into chunks of SMEM_SIZE length,
// sorting each chunk using the same algorithm as the bitonic_sort_small
// function and then arranging the chunks in pairs of ascending | descending
__global__ void bitonic_sort_chunks(int* d_in) {
    __shared__ int smem[SMEM_SIZE];
    uint idx = threadIdx.x;
    uint block_offset = blockIdx.x * SMEM_SIZE;
    smem[idx + 0]             = d_in[block_offset + idx + 0];
    smem[idx + SMEM_SIZE / 2] = d_in[block_offset + idx + SMEM_SIZE / 2];
    __syncthreads();
    bool ascending;
    for (uint size = 2; size < SMEM_SIZE; size <<= 1) {
        // bitmerge: we have to select which threads will be doing sorting in ascending
        // order and which ones will be doing it in descending order
        ascending = !(idx & (size / 2));
        for (uint stride = size / 2; stride > 0; stride >>= 1) {
            uint pos = 2 * idx - (idx % stride);
            int left = smem[pos];
            int right = smem[pos + stride];
            if (
                ( (left > right) &&  ascending ) ||
                ( (left < right) && !ascending )
            ) {
                int temp = left;
                smem[pos] = smem[pos + stride];
                smem[pos + stride] = temp;
            }
            __syncthreads();
        }
    }
    // last bitmerge, even chunks are to be sorted in ascending order
    // and odd chunks in descending order
    ascending = !(blockIdx.x & 1);
    for (uint stride = SMEM_SIZE / 2; stride > 0; stride >>= 1) {
        uint pos = 2 * idx - (idx % stride);
            int left = smem[pos];
            int right = smem[pos + stride];
            if (
                ( (left > right) &&  ascending ) ||
                ( (left < right) && !ascending )
            ) {
                int temp = left;
                smem[pos] = smem[pos + stride];
                smem[pos + stride] = temp;
            }
            __syncthreads();
    }
    d_in[block_offset + idx + 0]             = smem[idx + 0];
    d_in[block_offset + idx + SMEM_SIZE / 2] = smem[idx + SMEM_SIZE / 2];
}


// one step of bitonic merge using global memory for arrays whose
// length exceeds SMEM_SIZE 
__global__ void bitonic_merge_step(int* d_in, uint size, uint stride) {
    uint idx = blockDim.x * blockIdx.x + threadIdx.x;
    bool ascending = !(idx & (size / 2));
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
    return;
}


double bit_sort(int* array, uint length) {
    cudaEvent_t start_alloc, stop_alloc, start_kernel, stop_kernel, start_copy, stop_copy;
    CHECK(cudaEventCreate(&start_alloc));
    CHECK(cudaEventCreate(&stop_alloc));
    CHECK(cudaEventCreate(&start_kernel));
    CHECK(cudaEventCreate(&stop_kernel));
    CHECK(cudaEventCreate(&start_copy));
    CHECK(cudaEventCreate(&stop_copy));

    int* dev_array;
    size_t bytes = length*sizeof(int);

    CHECK(cudaEventRecord(start_alloc));
    CHECK(cudaMalloc(&dev_array, bytes));
    CHECK(cudaMemcpy(dev_array, array, bytes, cudaMemcpyHostToDevice));
    CHECK(cudaEventRecord(stop_alloc));

    uint threads = min(NUM_THREADS, length/2);
    uint blocks = (length/2 + threads - 1) / threads;
    uint smem_size = min(SMEM_SIZE, length);

    // printf("Threads: %d, blocks: %d, SMEM: %d\n", threads, blocks, smem_size);
    if (length <= SMEM_SIZE) {
        CHECK(cudaEventRecord(start_kernel));
        bitonic_sort_small<<<blocks, threads, smem_size * sizeof(int)>>>(dev_array, length);
        CHECK(cudaEventRecord(stop_kernel));
    } else {
        CHECK(cudaEventRecord(start_kernel));
        // do bitonic sort in shared memory until you can (i.e. until size <= SMEM_SIZE)
        bitonic_sort_chunks<<<blocks, threads>>>(dev_array);
        // now do the rest in global memory using iterated calls to the kernel in order to
        // synchronize threads across blocks        
        for (uint size = 2 * SMEM_SIZE; size <= length; size <<= 1) {
            // bitmerge using global memory
            for (uint stride = size / 2; stride > 0; stride >>= 1) {
                bitonic_merge_step<<<blocks, threads>>>(dev_array, size, stride);
            }
        }
        CHECK(cudaEventRecord(stop_kernel));

    }
    CHECK(cudaEventRecord(start_copy));
    CHECK(cudaMemcpy(array, dev_array, bytes, cudaMemcpyDeviceToHost));
    CHECK(cudaFree(dev_array));
    CHECK(cudaEventRecord(stop_copy));

    CHECK(cudaEventSynchronize(stop_copy));

    float t_alloc, t_kernel, t_copy;
    CHECK(cudaEventElapsedTime(&t_alloc, start_alloc, stop_alloc));
    CHECK(cudaEventElapsedTime(&t_kernel, start_kernel, stop_kernel));
    CHECK(cudaEventElapsedTime(&t_copy, start_copy, stop_copy));
    
    double gpu_time = (t_alloc + t_kernel + t_copy);
    
    CHECK(cudaEventDestroy(start_alloc));
    CHECK(cudaEventDestroy(stop_alloc));
    CHECK(cudaEventDestroy(start_kernel));
    CHECK(cudaEventDestroy(stop_kernel));
    CHECK(cudaEventDestroy(start_copy));
    CHECK(cudaEventDestroy(stop_copy));

    return gpu_time;
}
