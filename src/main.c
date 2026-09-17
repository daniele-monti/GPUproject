#include "../src/sort.h"
#include "../src/types.h"
#include "../src/utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main() {
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

    test_array = random_integers(n, min, max, time(NULL)+6);
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
