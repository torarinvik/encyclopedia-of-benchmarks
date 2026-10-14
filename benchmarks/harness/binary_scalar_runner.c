/* Portable C11 runner for two-unsigned-input scalar algorithms. */
#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

typedef int64_t (*binary_scalar_fn)(uint64_t, uint64_t);
extern int64_t BENCHMARK_FUNCTION(uint64_t left, uint64_t right);
static binary_scalar_fn volatile run_algorithm = BENCHMARK_FUNCTION;

static int parse_u64(const char *text, uint64_t *value)
{
    char *end = NULL;
    unsigned long long parsed;
    if (text[0] == '-' || text[0] == '\0') return 0;
    errno = 0;
    parsed = strtoull(text, &end, 10);
    if (errno == ERANGE || end == text || *end != '\0') return 0;
    *value = (uint64_t)parsed;
    return 1;
}

static int parse_i64(const char *text, int64_t *value)
{
    char *end = NULL;
    long long parsed;
    if (text[0] == '\0') return 0;
    errno = 0;
    parsed = strtoll(text, &end, 10);
    if (errno == ERANGE || end == text || *end != '\0') return 0;
    *value = (int64_t)parsed;
    return 1;
}

static int64_t run_batch(uint64_t left, uint64_t right, size_t repetitions, uint64_t *checksum)
{
    int64_t result = 0;
    uint64_t local_checksum = 0;
    for (size_t repetition = 0; repetition < repetitions; ++repetition) {
        result = run_algorithm(left, right);
        local_checksum += (uint64_t)result;
    }
    *checksum = local_checksum;
    return result;
}

int main(int argc, char **argv)
{
    uint64_t left, right, samples_arg, warmups_arg, repetitions_arg;
    int64_t expected;
    if (argc != 7 || !parse_u64(argv[1], &left) || !parse_u64(argv[2], &right) ||
        !parse_i64(argv[3], &expected) || !parse_u64(argv[4], &samples_arg) ||
        !parse_u64(argv[5], &warmups_arg) || !parse_u64(argv[6], &repetitions_arg) ||
        samples_arg == 0 || samples_arg > 10000 || warmups_arg > 100000 ||
        repetitions_arg == 0 || repetitions_arg > 1000000000) {
        fprintf(stderr, "usage: binary_scalar_runner LEFT RIGHT EXPECTED SAMPLES WARMUPS REPETITIONS\n");
        return 2;
    }

    const size_t sample_count = (size_t)samples_arg;
    const size_t warmup_count = (size_t)warmups_arg;
    const size_t repetitions = (size_t)repetitions_arg;
    uint64_t *sample_ns = malloc(sample_count * sizeof(*sample_ns));
    if (sample_ns == NULL) {
        fprintf(stderr, "unable to allocate sample data\n");
        return 2;
    }
    if (run_algorithm(left, right) != expected) {
        fprintf(stderr, "correctness mismatch for input pair\n");
        free(sample_ns);
        return 3;
    }

    volatile uint64_t warmup_observer = 0;
    for (size_t warmup = 0; warmup < warmup_count; ++warmup) {
        uint64_t checksum = 0;
        const int64_t result = run_batch(left, right, repetitions, &checksum);
        if (result != expected) {
            fprintf(stderr, "algorithm result changed during warmup\n");
            free(sample_ns);
            return 3;
        }
        warmup_observer ^= checksum;
    }

    uint64_t total_checksum = 0;
    int64_t observed_result = expected;
    for (size_t sample = 0; sample < sample_count; ++sample) {
        const clock_t start = clock();
        if (start == (clock_t)-1) {
            fprintf(stderr, "clock() failed before a sample\n");
            free(sample_ns);
            return 4;
        }
        uint64_t checksum = 0;
        observed_result = run_batch(left, right, repetitions, &checksum);
        const clock_t finish = clock();
        if (finish == (clock_t)-1 || finish < start) {
            fprintf(stderr, "clock() failed during a sample\n");
            free(sample_ns);
            return 4;
        }
        if (observed_result != expected) {
            fprintf(stderr, "correctness mismatch after a sample\n");
            free(sample_ns);
            return 3;
        }
        total_checksum += checksum;
        const long double elapsed_ns =
            ((long double)(finish - start) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
    }

    printf("{\"observed_result\":%" PRId64 ",\"samples_ns\":[", observed_result);
    for (size_t sample = 0; sample < sample_count; ++sample) {
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    }
    printf("],\"result_checksum\":%" PRIu64
           ",\"timer_resolution_ns\":%.3Lf}\n",
           total_checksum, 1000000000.0L / (long double)CLOCKS_PER_SEC);
    (void)warmup_observer;
    free(sample_ns);
    return 0;
}
