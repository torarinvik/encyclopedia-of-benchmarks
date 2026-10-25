/* Bounded-input checker for portable in-place sorting implementations. */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported sort symbol>"
#endif

#ifndef BENCHMARK_SORT_CHECKER_MAX_LENGTH
#define BENCHMARK_SORT_CHECKER_MAX_LENGTH 256
#endif

#ifndef BENCHMARK_SCRATCH_EXTRA
#define BENCHMARK_SCRATCH_EXTRA 0
#endif

#define MAX_SORT_LENGTH BENCHMARK_SORT_CHECKER_MAX_LENGTH
#if defined(BENCHMARK_WITH_SCRATCH)
extern void BENCHMARK_FUNCTION(int64_t *values, int64_t *scratch, size_t length);
#else
extern void BENCHMARK_FUNCTION(int64_t *values, size_t length);
#endif

static void run_sort(int64_t *values, int64_t *scratch, size_t length)
{
#if defined(BENCHMARK_WITH_SCRATCH)
    BENCHMARK_FUNCTION(values, scratch, length);
#else
    (void)scratch;
    BENCHMARK_FUNCTION(values, length);
#endif
}

static int compare_i64(const void *left, const void *right)
{
    const int64_t a = *(const int64_t *)left;
    const int64_t b = *(const int64_t *)right;
    return (a > b) - (a < b);
}

int main(void)
{
    uint64_t case_count;
    if (scanf("%" SCNu64, &case_count) != 1 || case_count == 0 || case_count > 1000000) {
        fprintf(stderr, "expected a nonempty sort case count\n");
        return 2;
    }
    for (uint64_t case_index = 0; case_index < case_count; ++case_index) {
        uint64_t length_value;
        if (scanf("%" SCNu64, &length_value) != 1 || length_value > MAX_SORT_LENGTH) {
            fprintf(stderr, "invalid sort case length at case=%" PRIu64 "\n", case_index);
            return 2;
        }
        const size_t length = (size_t)length_value;
        const size_t allocation_count = length == 0 ? 1 : length;
        if ((size_t)BENCHMARK_SCRATCH_EXTRA > SIZE_MAX / sizeof(int64_t) - allocation_count) {
            fprintf(stderr, "sort scratch allocation is outside the supported range\n");
            return 2;
        }
        int64_t *observed = calloc(allocation_count, sizeof(*observed));
        int64_t *expected = calloc(allocation_count, sizeof(*expected));
        int64_t *scratch = NULL;
#if defined(BENCHMARK_WITH_SCRATCH)
        scratch = calloc(allocation_count + (size_t)BENCHMARK_SCRATCH_EXTRA, sizeof(*scratch));
#endif
        if (observed == NULL || expected == NULL
#if defined(BENCHMARK_WITH_SCRATCH)
                || scratch == NULL
#endif
        ) {
            fprintf(stderr, "unable to allocate sort checker data\n");
            free(observed);
            free(expected);
            free(scratch);
            return 2;
        }
        for (size_t index = 0; index < length; ++index) {
            if (scanf("%" SCNd64, &observed[index]) != 1) {
                fprintf(stderr, "truncated sort input at case=%" PRIu64 "\n", case_index);
                free(observed);
                free(expected);
                free(scratch);
                return 2;
            }
            expected[index] = observed[index];
        }
        qsort(expected, length, sizeof(*expected), compare_i64);
        run_sort(observed, scratch, length);
        if (length != 0 && memcmp(observed, expected, length * sizeof(*expected)) != 0) {
            fprintf(stderr, "sort mismatch at case=%" PRIu64 "\n", case_index);
            free(observed);
            free(expected);
            free(scratch);
            return 3;
        }
        free(observed);
        free(expected);
        free(scratch);
    }
    char extra;
    if (scanf(" %c", &extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing sort checker input\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", case_count);
    return 0;
}
