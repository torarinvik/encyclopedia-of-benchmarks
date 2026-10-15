/* Batch checker for scalar algorithms that consume a read-only i64 array. */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

extern int64_t BENCHMARK_FUNCTION(const int64_t *values, size_t length);

int main(void)
{
    uint64_t case_count, checked = 0;
    if (scanf("%" SCNu64, &case_count) != 1 || case_count == 0 || case_count > 1000000) {
        fprintf(stderr, "expected a nonempty case count\n");
        return 2;
    }
    while (checked < case_count) {
        uint64_t length;
        int64_t expected;
        if (scanf("%" SCNu64 " %" SCNd64, &length, &expected) != 2 || length > 100001) {
            fprintf(stderr, "invalid array case header\n");
            return 2;
        }
        int64_t *values = length == 0 ? NULL : malloc((size_t)length * sizeof(*values));
        if (length != 0 && values == NULL) {
            fprintf(stderr, "unable to allocate checker input\n");
            return 2;
        }
        for (size_t index = 0; index < (size_t)length; ++index) {
            if (scanf("%" SCNd64, &values[index]) != 1) {
                free(values);
                fprintf(stderr, "truncated array input\n");
                return 2;
            }
        }
        const int64_t observed = BENCHMARK_FUNCTION(values, (size_t)length);
        free(values);
        if (observed != expected) {
            fprintf(stderr, "case=%" PRIu64 ": expected %" PRId64 ", observed %" PRId64 "\n",
                    checked, expected, observed);
            return 3;
        }
        ++checked;
    }
    uint64_t extra;
    if (scanf("%" SCNu64, &extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing checker input\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", checked);
    return 0;
}
