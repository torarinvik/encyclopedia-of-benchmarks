/* Batch checker for caller-buffered indexed-tree value traversals. */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

#define MAX_NODE_COUNT 100
#define OUTPUT_CANARY INT64_C(0x5A5A5A5A5A5A5A5A)
extern int64_t BENCHMARK_FUNCTION(const int64_t *, size_t, int64_t, int64_t *, size_t);

int main(void)
{
    uint64_t case_count;
    if (scanf("%" SCNu64, &case_count) != 1 || case_count == 0 || case_count > 1000000) {
        fprintf(stderr, "expected a nonempty tree case count\n");
        return 2;
    }
    for (uint64_t checked = 0; checked < case_count; ++checked) {
        uint64_t node_count_arg, expected_count_arg, capacity_arg;
        int64_t root_index, expected_result;
        if (scanf("%" SCNu64 " %" SCNd64 " %" SCNd64 " %" SCNu64 " %" SCNu64,
                  &node_count_arg, &root_index, &expected_result, &expected_count_arg,
                  &capacity_arg) != 5 || node_count_arg > MAX_NODE_COUNT ||
            expected_count_arg > MAX_NODE_COUNT || capacity_arg > MAX_NODE_COUNT) {
            fprintf(stderr, "invalid tree checker header\n");
            return 2;
        }
        const size_t node_count = (size_t)node_count_arg;
        const size_t expected_count = (size_t)expected_count_arg;
        const size_t capacity = (size_t)capacity_arg;
        int64_t *nodes = node_count == 0 ? NULL : malloc(3 * node_count * sizeof(*nodes));
        int64_t *expected = expected_count == 0 ? NULL : malloc(expected_count * sizeof(*expected));
        int64_t *output = malloc((node_count + 1) * sizeof(*output));
        if ((node_count != 0 && nodes == NULL) || (expected_count != 0 && expected == NULL) || output == NULL) {
            free(nodes); free(expected); free(output);
            fprintf(stderr, "unable to allocate tree checker buffers\n");
            return 2;
        }
        for (size_t index = 0; index < 3 * node_count; ++index) {
            if (scanf("%" SCNd64, &nodes[index]) != 1) {
                free(nodes); free(expected); free(output);
                fprintf(stderr, "truncated indexed tree input\n");
                return 2;
            }
        }
        for (size_t index = 0; index < expected_count; ++index) {
            if (scanf("%" SCNd64, &expected[index]) != 1) {
                free(nodes); free(expected); free(output);
                fprintf(stderr, "truncated expected traversal output\n");
                return 2;
            }
        }
        for (size_t index = 0; index <= node_count; ++index) output[index] = OUTPUT_CANARY;
        const int64_t observed = BENCHMARK_FUNCTION(nodes, node_count, root_index, output, capacity);
        int matches = observed == expected_result;
        if (observed >= 0) {
            matches = matches && (size_t)observed == expected_count &&
                (expected_count == 0 || memcmp(output, expected, expected_count * sizeof(*output)) == 0) &&
                output[(size_t)observed] == OUTPUT_CANARY;
        } else {
            matches = matches && output[0] == OUTPUT_CANARY;
        }
        if (!matches) {
            fprintf(stderr, "case=%" PRIu64 ": expected result=%" PRId64
                    ", observed result=%" PRId64 "\n", checked, expected_result, observed);
            free(nodes); free(expected); free(output);
            return 3;
        }
        free(nodes); free(expected); free(output);
    }
    char extra;
    if (scanf(" %c", &extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing checker input\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", case_count);
    return 0;
}
