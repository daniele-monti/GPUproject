#ifndef _UTILS_H
#define _UTILS_H
#include "common.h"

int* random_integers(uint n, int min, int max, uint seed);

void print_array(int* array, uint length);

bool is_array_sorted(int *array, uint length);

double milli_seconds();

#endif
