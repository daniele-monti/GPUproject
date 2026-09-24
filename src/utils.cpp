#include "utils.h"
#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>

int* random_integers(uint n, int min, int max, uint seed) {
    srand(seed);
    int* array = (int*)malloc(n * sizeof(int));
    if (array == NULL) {
        printf("Error: memory allocation failed\n");
        return NULL;
    }
    for (uint i = 0; i < n; i++) {
        array[i] = min + rand() % (max - min + 1);
    }
    return array;
}


void print_array(int* array, uint length) {
    printf("[");
    for (uint i = 0; i < length-1; i++) {
        printf("%d, ", array[i]);
    }
    printf("%d]\n", array[length-1]);
}


bool is_array_sorted(int *array, uint length) {
    for (uint i = 0; i < length - 1; i++)
		if (array[i] > array[i + 1]) {
            printf("validation FAILED:\n");
			printf("array[%d]=%d, but array[%d]=%d\n", i, array[i], i+1, array[i+1]);
            return false;
		}
	printf("validation PASSED\n");
    return true;
}


double milli_seconds() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)(ts.tv_sec * 1000) + (double)ts.tv_nsec / 1000000.0;
}
