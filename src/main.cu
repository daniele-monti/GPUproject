#include "sort.h"
#include "utils.h"
#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <pthread.h>

#define START 1024
#define STEP 2
#define FINISH 1024 * 1024 * 1024

#define N 32

typedef struct {
    int thread_id;
    uint n;
    FILE *stats;
    pthread_mutex_t* mutex_file;
} ThreadData;

void* run(void* arg) {
    double quick, merge, bit;
    double speedup_merge, speedup_quick;
    int min = -1000;
    int max = 1000;
    ThreadData* data = (ThreadData*) arg;

    int *q, *m, *b;
    q = random_integers(data->n, min, max, data->thread_id + 11);
    size_t bytes = data->n*sizeof(int);
    m = (int*)malloc(bytes);
    b = (int*)malloc(bytes);
    memcpy(m, q, bytes);
    memcpy(b, q, bytes);

    
    quick = quick_sort(q, data->n);

    merge = merge_sort(m, data->n);

    bit = bit_sort(b, data->n);
    speedup_quick = quick / bit;
    speedup_merge = merge / bit;
    
    pthread_mutex_lock(data->mutex_file);
    fprintf(data->stats, "%d,%f,%f,%f,%f,%f\n", data->n, quick, merge, bit, speedup_quick, speedup_merge);
    fflush(data->stats);
    pthread_mutex_unlock(data->mutex_file);
    free(q);
    free(m);
    free(b);

    pthread_exit(NULL);
}


int main() {
    // 
    cudaFree(NULL);

    pthread_t threads[N];
    ThreadData args[N];

    pthread_mutex_t mutex;
    pthread_mutex_init(&mutex, NULL);
    
    FILE *stats;
    stats = fopen("stats.csv", "w");
    if (stats == NULL) {
        printf("Could not open file\n");
        return 1;
    }
    fprintf(stats, "Length,Quicksort,Mergesort,Bitsort,Speedup_q,Speedup_m\n");

    for (uint n = START; n <= FINISH; n *= STEP) {
        for (int i = 0; i < N; i++) {
            args[i].n = n;
            args[i].stats = stats;
            args[i].mutex_file = &mutex;
            
            int rc = pthread_create(&threads[i], NULL, run, (void*)&args[i]);
            if (rc) {
                fprintf(stderr, "Errore nella creazione del thread %d\n", i);
                exit(-1);
            }
        }
        
        for (int i = 0; i < N; i++) {
            pthread_join(threads[i], NULL);
        }
    }
    fclose(stats);
    pthread_mutex_destroy(&mutex);
    return 0;
}
