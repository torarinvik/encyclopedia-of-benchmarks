/*
 * Shared search timing runner for algorithms that expose the benchmark C ABI.
 * Keep this file portable C11; it intentionally contains no CPU-specific code.
 * Compile with -DBENCHMARK_FUNCTION=<symbol>, for example linear_search.
 */
#include <inttypes.h>
#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef int64_t (*search_fn)(const int64_t *, size_t, int64_t);

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported search symbol>"
#endif
extern int64_t BENCHMARK_FUNCTION(const int64_t *values, size_t length, int64_t target);

/* Volatile function-pointer reads prevent the repeated calls being folded away. */
static search_fn volatile search = BENCHMARK_FUNCTION;

static int parse_u64(const char *text, uint64_t *value)
{
    char *end = NULL;
    unsigned long long parsed;

    if (text[0] == '-' || text[0] == '\0') {
        return 0;
    }

    errno = 0;
    parsed = strtoull(text, &end, 10);
    if (errno == ERANGE || end == text || *end != '\0') {
        return 0;
    }

    *value = (uint64_t)parsed;
    return 1;
}

static int parse_i64(const char *text, int64_t *value)
{
    char *end = NULL;
    long long parsed;

    if (text[0] == '\0') {
        return 0;
    }

    errno = 0;
    parsed = strtoll(text, &end, 10);
    if (errno == ERANGE || end == text || *end != '\0') {
        return 0;
    }

    *value = (int64_t)parsed;
    return 1;
}

static int64_t run_batch(const int64_t *values, size_t length, int64_t target,
                         size_t repetitions, uint64_t *checksum)
{
    int64_t last_result = -1;
    uint64_t local_checksum = 0;

    for (size_t repetition = 0; repetition < repetitions; ++repetition) {
        last_result = search(values, length, target);
        local_checksum += (uint64_t)last_result;
    }

    *checksum = local_checksum;
    return last_result;
}

int main(int argc, char **argv)
{
    uint64_t length_arg;
    int64_t target;
    int64_t expected;
    uint64_t samples_arg;
    uint64_t warmups_arg;
    uint64_t repetitions_arg;
    const char *generation_kind;
    int64_t multiplier;
    int64_t modulus;
    int64_t offset;

    if (argc != 11 ||
        !parse_u64(argv[1], &length_arg) ||
        !parse_i64(argv[2], &target) ||
        !parse_i64(argv[3], &expected) ||
        !parse_u64(argv[4], &samples_arg) ||
        !parse_u64(argv[5], &warmups_arg) ||
        !parse_u64(argv[6], &repetitions_arg) ||
        !parse_i64(argv[8], &multiplier) ||
        !parse_i64(argv[9], &modulus) ||
        !parse_i64(argv[10], &offset)) {
        fprintf(stderr,
                "usage: runner LENGTH TARGET EXPECTED SAMPLES WARMUPS REPETITIONS "
                "GENERATION MULTIPLIER MODULUS OFFSET\n");
        return 2;
    }
    generation_kind = argv[7];

    if (length_arg > SIZE_MAX / sizeof(int64_t) || length_arg > INT64_MAX ||
        samples_arg == 0 || samples_arg > 10000 ||
        warmups_arg > 100000 || repetitions_arg == 0 ||
        repetitions_arg > 1000000000 || multiplier <= 0 || offset < 0 ||
        (strcmp(generation_kind, "modular_affine") != 0 &&
         strcmp(generation_kind, "ascending") != 0) ||
        (strcmp(generation_kind, "modular_affine") == 0 && modulus <= 0)) {
        fprintf(stderr, "runner argument is outside the supported range\n");
        return 2;
    }

    const size_t length = (size_t)length_arg;
    const size_t sample_count = (size_t)samples_arg;
    const size_t warmup_count = (size_t)warmups_arg;
    const size_t repetitions = (size_t)repetitions_arg;
    const size_t allocation_count = length == 0 ? 1 : length;
    int64_t *values = malloc(allocation_count * sizeof(*values));
    uint64_t *sample_ns = malloc(sample_count * sizeof(*sample_ns));
    if (values == NULL || sample_ns == NULL) {
        fprintf(stderr, "unable to allocate workload data\n");
        free(values);
        free(sample_ns);
        return 2;
    }

    for (size_t index = 0; index < length; ++index) {
        if ((uint64_t)index > (uint64_t)(INT64_MAX / multiplier)) {
            fprintf(stderr, "input formula overflows signed 64-bit arithmetic\n");
            free(values);
            free(sample_ns);
            return 2;
        }
        const int64_t scaled_index = (int64_t)index * multiplier;
        if (strcmp(generation_kind, "modular_affine") == 0) {
            values[index] = (scaled_index % modulus) - offset;
        } else {
            values[index] = scaled_index - offset;
        }
    }

    const int64_t checked_result = search(values, length, target);
    if (checked_result != expected) {
        fprintf(stderr, "correctness mismatch: expected %" PRId64 ", got %" PRId64 "\n",
                expected, checked_result);
        free(values);
        free(sample_ns);
        return 3;
    }

    volatile uint64_t warmup_observer = 0;
    for (size_t warmup = 0; warmup < warmup_count; ++warmup) {
        uint64_t checksum = 0;
        (void)run_batch(values, length, target, repetitions, &checksum);
        warmup_observer ^= checksum;
    }

    uint64_t total_checksum = 0;
    for (size_t sample = 0; sample < sample_count; ++sample) {
        const clock_t start = clock();
        if (start == (clock_t)-1) {
            fprintf(stderr, "clock() failed before a sample\n");
            free(values);
            free(sample_ns);
            return 4;
        }

        uint64_t checksum = 0;
        const int64_t timed_result = run_batch(values, length, target, repetitions, &checksum);

        const clock_t finish = clock();
        if (finish == (clock_t)-1 || finish < start) {
            fprintf(stderr, "clock() failed during a sample\n");
            free(values);
            free(sample_ns);
            return 4;
        }
        if (timed_result != expected) {
            fprintf(stderr, "timed result changed: expected %" PRId64 ", got %" PRId64 "\n",
                    expected, timed_result);
            free(values);
            free(sample_ns);
            return 3;
        }

        const long double elapsed_ns =
            ((long double)(finish - start) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
        total_checksum += checksum;
    }

    /* Keep the warmup work observable too, while reporting only timed checksums. */
    warmup_observer ^= total_checksum;
    (void)warmup_observer;

    printf("{\"observed_result\":%" PRId64 ",\"samples_ns\":[", checked_result);
    for (size_t sample = 0; sample < sample_count; ++sample) {
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    }
    printf("],\"result_checksum\":%" PRIu64 ",\"timer_resolution_ns\":%.3Lf}\n",
           total_checksum, 1000000000.0L / (long double)CLOCKS_PER_SEC);

    free(values);
    free(sample_ns);
    return 0;
}
