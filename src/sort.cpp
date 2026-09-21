#include "sort.h"
#include "types.h"
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
