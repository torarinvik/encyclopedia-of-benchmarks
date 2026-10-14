/* Portable C11 runner for in-place sorting implementations. */
#include <errno.h>
#include <inttypes.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported sort symbol>"
#endif

#ifndef BENCHMARK_SCRATCH_EXTRA
#define BENCHMARK_SCRATCH_EXTRA 0
#endif

#ifdef BENCHMARK_WITH_SCRATCH
typedef void (*sort_fn)(int64_t *, int64_t *, size_t);
extern void BENCHMARK_FUNCTION(int64_t *values, int64_t *scratch, size_t length);
#else
typedef void (*sort_fn)(int64_t *, size_t);
extern void BENCHMARK_FUNCTION(int64_t *values, size_t length);
#endif
static sort_fn volatile sort_values = BENCHMARK_FUNCTION;

static void run_sort(int64_t *values, int64_t *scratch, size_t length)
{
#ifdef BENCHMARK_WITH_SCRATCH
    sort_values(values, scratch, length);
#else
    (void)scratch;
    sort_values(values, length);
#endif
}

static void release_scratch(int64_t *scratch)
{
#ifdef BENCHMARK_WITH_SCRATCH
    free(scratch);
#else
    (void)scratch;
#endif
}

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

static int compare_i64(const void *left, const void *right)
{
    const int64_t a = *(const int64_t *)left;
    const int64_t b = *(const int64_t *)right;
    return (a > b) - (a < b);
}

static int matches_reference(const int64_t *values, const int64_t *reference,
                              size_t length)
{
    return length == 0 || memcmp(values, reference, length * sizeof(*values)) == 0;
}

static uint64_t sorted_checksum(const int64_t *values, size_t length)
{
    uint64_t checksum = UINT64_C(14695981039346656037);
    for (size_t index = 0; index < length; ++index) {
        checksum = (checksum ^ (uint64_t)values[index]) * UINT64_C(1099511628211);
    }
    return checksum;
}

int main(int argc, char **argv)
{
    uint64_t length_arg;
    uint64_t samples_arg;
    uint64_t warmups_arg;
    uint64_t multiplier_arg;
    uint64_t modulus_arg;
    uint64_t offset_arg;
    int64_t multiplier;
    int64_t modulus;
    int64_t offset;
    if (argc != 7 || !parse_u64(argv[1], &length_arg) ||
        !parse_u64(argv[2], &samples_arg) || !parse_u64(argv[3], &warmups_arg) ||
        !parse_u64(argv[4], &multiplier_arg) ||
        !parse_u64(argv[5], &modulus_arg) ||
        !parse_u64(argv[6], &offset_arg)) {
        fprintf(stderr, "usage: sort_runner LENGTH SAMPLES WARMUPS MULTIPLIER MODULUS OFFSET\n");
        return 2;
    }
    if (multiplier_arg > INT64_MAX || modulus_arg > INT64_MAX || offset_arg > INT64_MAX) {
        fprintf(stderr, "sort runner argument is outside the supported range\n");
        return 2;
    }
    multiplier = (int64_t)multiplier_arg;
    modulus = (int64_t)modulus_arg;
    offset = (int64_t)offset_arg;
    const uint64_t maximum_elements = (uint64_t)(SIZE_MAX / sizeof(int64_t));
    const uint64_t scratch_extra = (uint64_t)BENCHMARK_SCRATCH_EXTRA;
    const uint64_t allocation_arg = length_arg == 0 ? 1 : length_arg;
    if (scratch_extra > maximum_elements || allocation_arg > maximum_elements - scratch_extra ||
        length_arg > INT64_MAX ||
        samples_arg == 0 || samples_arg > 10000 || warmups_arg > 100000 ||
        multiplier <= 0 || modulus <= 0 || offset < 0 ||
        length_arg > (uint64_t)(INT64_MAX / multiplier)) {
        fprintf(stderr, "sort runner argument is outside the supported range\n");
        return 2;
    }

    const size_t length = (size_t)length_arg;
    const size_t sample_count = (size_t)samples_arg;
    const size_t warmup_count = (size_t)warmups_arg;
    const size_t allocation_count = length == 0 ? 1 : length;
    const size_t scratch_count = allocation_count + (size_t)BENCHMARK_SCRATCH_EXTRA;
    int64_t *input = malloc(allocation_count * sizeof(*input));
    int64_t *working = malloc(allocation_count * sizeof(*working));
    int64_t *reference = malloc(allocation_count * sizeof(*reference));
    int64_t *scratch = NULL;
#ifdef BENCHMARK_WITH_SCRATCH
    scratch = malloc(scratch_count * sizeof(*scratch));
#endif
    uint64_t *sample_ns = malloc(sample_count * sizeof(*sample_ns));
    if (input == NULL || working == NULL || reference == NULL || sample_ns == NULL
#ifdef BENCHMARK_WITH_SCRATCH
        || scratch == NULL
#endif
    ) {
        fprintf(stderr, "unable to allocate sort workload data\n");
        free(input);
        free(working);
        free(reference);
        release_scratch(scratch);
        free(sample_ns);
        return 2;
    }

    for (size_t index = 0; index < length; ++index) {
        const int64_t scaled = (int64_t)index * multiplier;
        input[index] = (scaled % modulus) - offset;
    }
    if (length == 0) {
        input[0] = 0;
    }
    memcpy(reference, input, allocation_count * sizeof(*input));
    qsort(reference, length, sizeof(*reference), compare_i64);

    for (size_t warmup = 0; warmup < warmup_count; ++warmup) {
        memcpy(working, input, length * sizeof(*input));
        run_sort(working, scratch, length);
        if (!matches_reference(working, reference, length)) {
            fprintf(stderr, "sort result differs from the reference after a warmup\n");
            free(input);
            free(working);
            free(reference);
            release_scratch(scratch);
            free(sample_ns);
            return 3;
        }
    }

    for (size_t sample = 0; sample < sample_count; ++sample) {
        memcpy(working, input, length * sizeof(*input));
        const clock_t start = clock();
        if (start == (clock_t)-1) {
            fprintf(stderr, "clock() failed before a sample\n");
            free(input);
            free(working);
            free(reference);
            release_scratch(scratch);
            free(sample_ns);
            return 4;
        }
        run_sort(working, scratch, length);
        const clock_t finish = clock();
        if (finish == (clock_t)-1 || finish < start) {
            fprintf(stderr, "clock() failed during a sample\n");
            free(input);
            free(working);
            free(reference);
            release_scratch(scratch);
            free(sample_ns);
            return 4;
        }
        if (!matches_reference(working, reference, length)) {
            fprintf(stderr, "sort result differs from the reference after a sample\n");
            free(input);
            free(working);
            free(reference);
            release_scratch(scratch);
            free(sample_ns);
            return 3;
        }
        const long double elapsed_ns =
            ((long double)(finish - start) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
    }

    printf("{\"observed_result\":%" PRIu64 ",\"samples_ns\":[", length_arg);
    for (size_t sample = 0; sample < sample_count; ++sample) {
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    }
    printf("],\"result_checksum\":%" PRIu64 ",\"timer_resolution_ns\":%.3Lf}\n",
           sorted_checksum(reference, length), 1000000000.0L / (long double)CLOCKS_PER_SEC);

    free(input);
    free(working);
    free(reference);
    release_scratch(scratch);
    free(sample_ns);
    return 0;
}
