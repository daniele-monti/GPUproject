#ifndef _UTILS_H
#define _UTILS_H
#include "types.h"
#include <stdio.h>

void print_array(int* array, uint length) {
    printf("[");
    for (int i = 0; i < length-1; i++) {
        printf("%d, ", array[i]);
    }
    printf("%d]\n", array[length-1]);
}

#endif
