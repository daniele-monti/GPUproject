#include "../sort.h"
#include "../types.h"
#include "../utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int* random_integers(int n, int min, int max) {
    int* array = (int*)malloc(n * sizeof(int));
    if (array == NULL) {
        printf("Error: memory allocation failed\n");
        return NULL;
    }
    for (int i = 0; i < n; i++) {
        array[i] = min + rand() % (max - min + 1);
    }
    return array;
}

int main() {
    int n = 10;
    int min = 1;
    int max = 100;
    
    srand(time(NULL));
    int* test_array = random_integers(n, min, max);
    if (test_array != NULL) {
        printf("Array of %d random numbers between %d and %d:\n", n, min, max);
        print_array(test_array, n);
        merge_sort(test_array, n);
        printf("Mergesort: ");
        print_array(test_array, n);
    }

    test_array = random_integers(n, min, max);
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
