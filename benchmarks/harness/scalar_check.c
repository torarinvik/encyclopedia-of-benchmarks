/* Batch correctness checker for the scalar C ABI; no timing is recorded here. */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported scalar symbol>"
#endif

extern int64_t BENCHMARK_FUNCTION(int64_t input);

int main(void)
{
    uint64_t count = 0;
    int64_t input;
    int64_t expected;
    int fields;
    while ((fields = scanf("%" SCNd64 " %" SCNd64, &input, &expected)) == 2) {
        const int64_t observed = BENCHMARK_FUNCTION(input);
        if (observed != expected) {
            fprintf(stderr, "input=%" PRId64 ": expected %" PRId64 ", observed %" PRId64 "\n",
                    input, expected, observed);
            return 3;
        }
        ++count;
    }
    if (fields != EOF || count == 0 || ferror(stdin)) {
        fprintf(stderr, "expected nonempty INPUT EXPECTED pairs on stdin\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", count);
    return 0;
}
