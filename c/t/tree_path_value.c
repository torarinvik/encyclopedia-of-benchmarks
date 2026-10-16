/* Port of Go Problem18's chunked search over its triangle-shaped DAG. */
#include <stddef.h>
#include <stdint.h>

#define TREE_PATH_MAX_NODES 120
#define TREE_PATH_MAX_DEPTH 14

int64_t tree_path_value(const int64_t *packed, size_t length) {
    if (packed == NULL || length < 1 || length > TREE_PATH_MAX_NODES + 1) return -1;
    if (packed[0] < 1 || packed[0] > TREE_PATH_MAX_DEPTH) return -1;
    const int depth = (int)packed[0];
    const size_t count = length - 1;
    if (count == 0) return 0;

    int64_t values[TREE_PATH_MAX_NODES];
    int left[TREE_PATH_MAX_NODES], right[TREE_PATH_MAX_NODES];
    for (size_t i = 0; i < count; ++i) {
        values[i] = packed[i + 1];
        left[i] = right[i] = -1;
        if ((i == 0 && (values[i] < -1000 || values[i] > 1000))
                || (i > 0 && (values[i] < 1 || values[i] > 1000))) return -1;
    }
    size_t row_start = 0, width = 1;
    while (row_start < count) {
        for (size_t column = 0; column < width && row_start + column < count; ++column) {
            const size_t parent = row_start + column;
            const size_t left_index = row_start + width + column;
            const size_t right_index = left_index + 1;
            if (left_index < count) left[parent] = (int)left_index;
            if (right_index < count) right[parent] = (int)right_index;
        }
        row_start += width;
        ++width;
    }

    int pivot = 0;
    int64_t maximum = values[0];
    while (left[pivot] >= 0) {
        int stack_node[TREE_PATH_MAX_DEPTH + 2];
        int stack_steps[TREE_PATH_MAX_DEPTH + 2];
        int64_t stack_sum[TREE_PATH_MAX_DEPTH + 2];
        size_t top = 0;
        stack_node[top] = pivot; stack_steps[top] = depth; stack_sum[top] = maximum; ++top;
        while (top > 0) {
            --top;
            const int node = stack_node[top];
            const int steps = stack_steps[top];
            const int64_t sum = stack_sum[top];
            if (steps == 0) {
                if (sum > maximum) { maximum = sum; pivot = node; }
                continue;
            }
            if (right[node] >= 0) {
                stack_node[top] = right[node]; stack_steps[top] = steps - 1;
                stack_sum[top] = sum + values[right[node]]; ++top;
            }
            if (left[node] >= 0) {
                stack_node[top] = left[node]; stack_steps[top] = steps - 1;
                stack_sum[top] = sum + values[left[node]]; ++top;
            } else if (sum > maximum) {
                maximum = sum; pivot = node;
            }
        }
    }
    return maximum;
}
