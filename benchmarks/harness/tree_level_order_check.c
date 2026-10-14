/* Batch correctness checker for indexed binary-tree level-order traversal. */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

#define MAX_NODE_COUNT 4097
#define OUTPUT_CANARY INT64_C(0x5A5A5A5A5A5A5A5A)
#define OFFSET_CANARY ((size_t)0x5A5A5A5A)
extern int64_t BENCHMARK_FUNCTION(const int64_t *nodes, size_t node_count, int64_t root_index,
                                  int64_t *output_values, size_t output_capacity,
                                  size_t *level_offsets, size_t level_offsets_capacity,
                                  size_t *queue, size_t queue_capacity);

int main(void)
{
    uint64_t case_count, checked = 0;
    if (scanf("%" SCNu64, &case_count) != 1 || case_count == 0 || case_count > 1000000) {
        fprintf(stderr, "expected a nonempty tree case count\n");
        return 2;
    }
    while (checked < case_count) {
        uint64_t node_count, expected_output_count, expected_offset_count;
        uint64_t output_capacity, offset_capacity, queue_capacity;
        int64_t root_index, expected_result;
        if (scanf("%" SCNu64 " %" SCNd64 " %" SCNd64 " %" SCNu64 " %" SCNu64
                  " %" SCNu64 " %" SCNu64 " %" SCNu64,
                  &node_count, &root_index, &expected_result, &expected_output_count,
                  &expected_offset_count, &output_capacity, &offset_capacity, &queue_capacity) != 8 ||
            node_count > MAX_NODE_COUNT || expected_result < -2 || expected_result > MAX_NODE_COUNT ||
            expected_output_count > MAX_NODE_COUNT || expected_offset_count > MAX_NODE_COUNT + 1 ||
            output_capacity > MAX_NODE_COUNT || offset_capacity > MAX_NODE_COUNT + 1 ||
            queue_capacity > MAX_NODE_COUNT) {
            fprintf(stderr, "invalid tree checker case header\n");
            return 2;
        }
        const size_t count = (size_t)node_count;
        int64_t *nodes = count == 0 ? NULL : malloc(3 * count * sizeof(*nodes));
        int64_t *expected_values = expected_output_count == 0 ? NULL :
            malloc((size_t)expected_output_count * sizeof(*expected_values));
        int64_t *observed_values = malloc((count + 1) * sizeof(*observed_values));
        size_t *expected_offsets = expected_offset_count == 0 ? NULL :
            malloc((size_t)expected_offset_count * sizeof(*expected_offsets));
        size_t *observed_offsets = malloc((count + 2) * sizeof(*observed_offsets));
        size_t *queue = malloc((count + 1) * sizeof(*queue));
        if ((count != 0 && nodes == NULL) || (expected_output_count != 0 && expected_values == NULL) ||
            observed_values == NULL || (expected_offset_count != 0 && expected_offsets == NULL) ||
            observed_offsets == NULL || queue == NULL) {
            free(nodes); free(expected_values); free(observed_values); free(expected_offsets);
            free(observed_offsets); free(queue);
            fprintf(stderr, "unable to allocate tree checker buffers\n");
            return 2;
        }
        for (size_t index = 0; index < 3 * count; ++index) {
            if (scanf("%" SCNd64, &nodes[index]) != 1) {
                fprintf(stderr, "truncated indexed tree input\n");
                free(nodes); free(expected_values); free(observed_values); free(expected_offsets);
                free(observed_offsets); free(queue); return 2;
            }
        }
        for (size_t index = 0; index < (size_t)expected_output_count; ++index) {
            if (scanf("%" SCNd64, &expected_values[index]) != 1) {
                fprintf(stderr, "truncated expected traversal output\n");
                free(nodes); free(expected_values); free(observed_values); free(expected_offsets);
                free(observed_offsets); free(queue); return 2;
            }
        }
        for (size_t index = 0; index < (size_t)expected_offset_count; ++index) {
            uint64_t value;
            if (scanf("%" SCNu64, &value) != 1 || value > count) {
                fprintf(stderr, "invalid expected level offset\n");
                free(nodes); free(expected_values); free(observed_values); free(expected_offsets);
                free(observed_offsets); free(queue); return 2;
            }
            expected_offsets[index] = (size_t)value;
        }
        for (size_t index = 0; index < count + 1; ++index) observed_values[index] = OUTPUT_CANARY;
        for (size_t index = 0; index < count + 2; ++index) observed_offsets[index] = OFFSET_CANARY;
        const int64_t result = BENCHMARK_FUNCTION(nodes, count, root_index, observed_values,
                                                   (size_t)output_capacity, observed_offsets,
                                                   (size_t)offset_capacity, queue,
                                                   (size_t)queue_capacity);
        int matches = result == expected_result;
        if (expected_result >= 0) {
            matches = matches && expected_output_count == node_count &&
                expected_offset_count == (uint64_t)expected_result + 1;
            if (matches && count != 0)
                matches = memcmp(observed_values, expected_values, count * sizeof(*observed_values)) == 0;
            if (matches && expected_offset_count != 0)
                matches = memcmp(observed_offsets, expected_offsets,
                                 (size_t)expected_offset_count * sizeof(*observed_offsets)) == 0;
        } else {
            matches = matches && observed_values[0] == OUTPUT_CANARY &&
                observed_offsets[0] == OFFSET_CANARY;
        }
        if (!matches) {
            fprintf(stderr, "case=%" PRIu64 ": expected result=%" PRId64
                    ", observed result=%" PRId64 "\n", checked, expected_result, result);
            free(nodes); free(expected_values); free(observed_values); free(expected_offsets);
            free(observed_offsets); free(queue); return 3;
        }
        free(nodes); free(expected_values); free(observed_values); free(expected_offsets);
        free(observed_offsets); free(queue);
        ++checked;
    }
    char extra;
    if (scanf(" %c", &extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing checker input\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", checked);
    return 0;
}
