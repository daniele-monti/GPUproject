#include "sort.h"
#include "utils.h"
#include "common.h"
#include <stdio.h>
#include <stdlib.h>

#define N 1024 * 1024 * 32

int main() {
    double start_merge, stop_merge;
    double start_quick, stop_quick;
    double start_bit, stop_bit;
    double speedup_merge, speedup_quick;
    int min = -1000;
    int max = 1000;
    
    int* array = random_integers(N, min, max, time(NULL));
    start_quick = milli_seconds();
    quick_sort(array, N);
    stop_quick = milli_seconds() - start_quick;
	printf("Quicksort took: %f milliseconds on an array of %d elements\n", stop_quick, N);

    array = random_integers(N, min, max, time(NULL));
    start_merge = milli_seconds();
    merge_sort(array, N);
    stop_merge = milli_seconds() - start_merge;
	printf("Mergesort took: %f milliseconds on an array of %d elements\n", stop_merge, N);

    array = random_integers(N, min, max, time(NULL));
    start_bit = milli_seconds();
    bit_sort(array, N);
    stop_bit = milli_seconds() - start_bit;
	printf("Bitsort took: %f milliseconds on an array of %d elements\n", stop_bit, N);
    speedup_quick = stop_quick / stop_bit;
    speedup_merge = stop_merge / stop_bit;
    printf("It had a speedup of %.3f on quicksort and of %.3f on mergesort\n", speedup_quick, speedup_merge);

    free(array);
    return 0;
}
