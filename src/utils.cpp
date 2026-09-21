#include "utils.h"
#include "types.h"
#include <stdio.h>
#include <stdlib.h>

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
