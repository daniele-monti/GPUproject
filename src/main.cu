#include "sort.h"
#include "utils.h"
#include "common.h"
#include <stdio.h>
#include <memory.h>
#include <stdlib.h>

#define START 1024
#define STEP 2
#define FINISH 1024 * 1024 * 1024

#define N 16

int main() {
    // Force cuda context initialization before the first call to bitsort
    cudaFree(NULL);

    FILE *stats;
    stats = fopen("stats.csv", "w");
    if (stats == NULL) {
        printf("Could not open file\n");
        return 1;
    }
    fprintf(stats, "Length,Quicksort,Mergesort,Bitsort,Speedup_q,Speedup_m\n");

    double start_merge, stop_merge;
    //double start_quick, stop_quick;
    double start_bit, stop_bit;
    double speedup_merge;// speedup_quick;
    int min = -1000;
    int max = 1000;

    for (uint n = START; n <= FINISH; n *= STEP) {
        for (uint i = 0; i < N; i++) {
            int *q, *m, *b;
            b = random_integers(n, min, max, n + i + 11);
            size_t bytes = n*sizeof(int);
            //q = (int*)malloc(bytes);
            m = (int*)malloc(bytes);
            memcpy(m, b, bytes);
            //memcpy(q, b, bytes);

            //start_quick = milli_seconds();
            //quick_sort(q, n);
            //stop_quick = milli_seconds() - start_quick;

            start_merge = milli_seconds();
            merge_sort(m, n);
            stop_merge = milli_seconds() - start_merge;

            start_bit = milli_seconds();
            bit_sort(b, n);
            stop_bit = milli_seconds() - start_bit;
            //speedup_quick = stop_quick / stop_bit;
            speedup_merge = stop_merge / stop_bit;

            fprintf(stats, "%d,%s,%f,%f,%s,%f\n", n, "", stop_merge, stop_bit, "", speedup_merge);
            fflush(stats);
            //free(q);
            free(m);
            free(b);
        }
    }
    fclose(stats);

    return 0;
}
