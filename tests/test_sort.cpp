#include "../src/sort.h"
#include "../src/common.h"
#include "../src/utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

void test_sort(double (*algorithm)(int*, uint), uint length, int min, int max) {
    int* test_array = random_integers(length, min, max, time(NULL));
    if (test_array != NULL) {
        printf("Generated array of %d random numbers between %d and %d\n", length, min, max);
        algorithm(test_array, length);
        is_array_sorted(test_array, length);
        printf("\n");
        free(test_array);
    }
}

int main() {
    int n = 1024;
    int min = -1000;
    int max = 1000;
    
    printf("Mergesort: ");
    test_sort(merge_sort, n, min, max);
    
    printf("Quicksort: ");
    test_sort(quick_sort, n, min, max);
    
    // #############################à
    
    n = 128;
    printf("Bitsort: ");
    test_sort(bit_sort, n, min, max);
    
    n = 512;
    printf("Bitsort: ");
    test_sort(bit_sort, n, min, max);

    n = 2048;
    printf("Bitsort: ");
    test_sort(bit_sort, n, min, max);
    
    n = 1024*1024;
    printf("Bitsort: ");
    test_sort(bit_sort, n, min, max);
    
    // 4 GiB of data
    n = 1024*1024*1024;
    printf("Bitsort: ");
    test_sort(bit_sort, n, min, max);
    return 0;
}
