#include "../src/sort.h"
#include "../src/common.h"
#include "../src/utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main() {
    int n = 1024;
    int min = -100;
    int max = 100;
    
    int* test_array = random_integers(n, min, max, time(NULL));
    if (test_array != NULL) {
        printf("Generated array of %d random numbers between %d and %d\n", n, min, max);
        merge_sort(test_array, n);
        printf("Mergesort: ");
        is_array_sorted(test_array, n);
    }

    test_array = random_integers(n, min, max, time(NULL)+12);
    if (test_array != NULL) {
        printf("Generated array of %d random numbers between %d and %d\n", n, min, max);
        quick_sort(test_array, n);
        printf("Quicksort: ");
        is_array_sorted(test_array, n);
    }

    test_array = random_integers(n, min, max, time(NULL)+12);
    if (test_array != NULL) {
        printf("Generated array of %d random numbers between %d and %d\n", n, min, max);
        bit_sort(test_array, n);
        printf("Bitsort: ");
        is_array_sorted(test_array, n);
        free(test_array);
    }
    return 0;
}
