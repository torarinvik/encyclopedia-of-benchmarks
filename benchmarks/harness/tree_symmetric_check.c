/* Batch checker for recursive binary-tree symmetry implementations. */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

#define MAX_NODE_COUNT 1023
extern int64_t BENCHMARK_FUNCTION(const int64_t *, size_t, int64_t);

int main(void)
{
    uint64_t case_count;
    if (scanf("%" SCNu64, &case_count) != 1 || case_count == 0 || case_count > 1000000) {
        fprintf(stderr, "expected a nonempty case count\n");
        return 2;
    }
    for (uint64_t checked = 0; checked < case_count; ++checked) {
        uint64_t node_count_arg;
        int64_t root_index, expected;
        if (scanf("%" SCNu64 " %" SCNd64 " %" SCNd64,
                  &node_count_arg, &root_index, &expected) != 3 || node_count_arg > MAX_NODE_COUNT) {
            fprintf(stderr, "invalid tree case header\n");
            return 2;
        }
        const size_t node_count = (size_t)node_count_arg;
        int64_t *nodes = node_count == 0 ? NULL : malloc(3 * node_count * sizeof(*nodes));
        if (node_count != 0 && nodes == NULL) {
            fprintf(stderr, "unable to allocate checker input\n");
            return 2;
        }
        for (size_t index = 0; index < 3 * node_count; ++index) {
            if (scanf("%" SCNd64, &nodes[index]) != 1) {
                free(nodes);
                fprintf(stderr, "truncated tree node table\n");
                return 2;
            }
        }
        const int64_t observed = BENCHMARK_FUNCTION(nodes, node_count, root_index);
        free(nodes);
        if (observed != expected) {
            fprintf(stderr, "case=%" PRIu64 ": expected %" PRId64 ", observed %" PRId64 "\n",
                    checked, expected, observed);
            return 3;
        }
    }
    uint64_t extra;
    if (scanf("%" SCNu64, &extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing checker input\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", case_count);
    return 0;
}
