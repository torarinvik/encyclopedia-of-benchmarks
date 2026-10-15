/* Batch correctness checker for a two-word scalar C ABI. */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

extern int64_t BENCHMARK_FUNCTION(uint64_t left, uint64_t right);

int main(void)
{
    uint64_t count = 0, left, right;
    int64_t expected;
    int fields;
    while ((fields = scanf("%" SCNu64 " %" SCNu64 " %" SCNd64, &left, &right, &expected)) == 3) {
        const int64_t observed = BENCHMARK_FUNCTION(left, right);
        if (observed != expected) {
            fprintf(stderr, "left=%" PRIu64 " right=%" PRIu64 ": expected %" PRId64 ", observed %" PRId64 "\n",
                    left, right, expected, observed);
            return 3;
        }
        ++count;
    }
    if (fields != EOF || count == 0 || ferror(stdin)) {
        fprintf(stderr, "expected nonempty LEFT RIGHT EXPECTED triples on stdin\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", count);
    return 0;
}
