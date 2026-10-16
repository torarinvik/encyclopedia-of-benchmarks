/* Batch exact checker for a three-input signed 64-bit algorithm. */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

extern int64_t BENCHMARK_FUNCTION(int64_t first, int64_t second, int64_t third);

int main(void)
{
    uint64_t case_count, checked = 0;
    if (scanf("%" SCNu64, &case_count) != 1 || case_count == 0 || case_count > 1000000) {
        fprintf(stderr, "expected a nonempty case count\n");
        return 2;
    }
    while (checked < case_count) {
        int64_t first, second, third, expected;
        if (scanf("%" SCNd64 " %" SCNd64 " %" SCNd64 " %" SCNd64,
                  &first, &second, &third, &expected) != 4) {
            fprintf(stderr, "truncated i64 triple case\n");
            return 2;
        }
        const int64_t observed = BENCHMARK_FUNCTION(first, second, third);
        if (observed != expected) {
            fprintf(stderr, "case=%" PRIu64 ": expected %" PRId64 ", observed %" PRId64 "\n",
                    checked, expected, observed);
            return 3;
        }
        ++checked;
    }
    char extra[2];
    if (scanf("%1s", extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing checker input\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", checked);
    return 0;
}
