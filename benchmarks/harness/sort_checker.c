/* Exhaustive small-input checker for scratch-free sorting implementations. */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported sort symbol>"
#endif

#define MAX_SORT_LENGTH 6
extern void BENCHMARK_FUNCTION(int64_t *values, size_t length);

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
        int64_t observed[MAX_SORT_LENGTH] = {0};
        int64_t expected[MAX_SORT_LENGTH] = {0};
        for (size_t index = 0; index < length; ++index) {
            if (scanf("%" SCNd64, &observed[index]) != 1) {
                fprintf(stderr, "truncated sort input at case=%" PRIu64 "\n", case_index);
                return 2;
            }
            expected[index] = observed[index];
        }
        qsort(expected, length, sizeof(*expected), compare_i64);
        BENCHMARK_FUNCTION(observed, length);
        if (length != 0 && memcmp(observed, expected, length * sizeof(*expected)) != 0) {
            fprintf(stderr, "sort mismatch at case=%" PRIu64 "\n", case_index);
            return 3;
        }
    }
    char extra;
    if (scanf(" %c", &extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing sort checker input\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", case_count);
    return 0;
}
