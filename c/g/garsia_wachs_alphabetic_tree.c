#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT (MAX_N + 2)
#define MAX_OUTPUT_BYTES (8 * (MAX_N + 1))
#define MAX_WEIGHT INT64_C(1000000)
#define GW_INFINITY (INT64_C(1) << 62)

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t garsia_wachs_alphabetic_tree(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N || length != (size_t)n_value + 1) return -1;
    const size_t n = (size_t)n_value;
    int64_t node_weight[2 * MAX_N - 1];
    int left[2 * MAX_N - 1], right[2 * MAX_N - 1];
    int active[MAX_N];
    for (size_t i = 0; i < 2 * n - 1; ++i) {
        node_weight[i] = 0;
        left[i] = right[i] = -1;
    }
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 0 || input[i + 1] > MAX_WEIGHT) return -1;
        node_weight[i] = input[i + 1];
        active[i] = (int)i;
    }

    /* Phase one: merge the first eligible adjacent pair and reinsert its sum. */
    size_t active_count = n;
    size_t next_node = n;
    while (active_count > 1) {
        size_t pair = 0;
        for (; pair + 1 < active_count; ++pair) {
            int64_t following = pair + 2 < active_count
                ? node_weight[active[pair + 2]] : GW_INFINITY;
            if (node_weight[active[pair]] <= following) break;
        }
        int first = active[pair], second = active[pair + 1];
        int64_t combined = node_weight[first] + node_weight[second];
        node_weight[next_node] = combined;
        left[next_node] = first;
        right[next_node] = second;
        size_t earlier = pair;
        while (earlier > 0 && node_weight[active[earlier - 1]] < combined) --earlier;
        size_t insert_at = earlier;
        for (size_t i = pair; i + 2 < active_count; ++i) active[i] = active[i + 2];
        active_count -= 2;
        for (size_t i = active_count; i > insert_at; --i) active[i] = active[i - 1];
        active[insert_at] = (int)next_node;
        ++active_count;
        ++next_node;
    }

    /* Phase two: extract leaf depths from the temporary merge tree. */
    int depths[MAX_N] = {0};
    int stack_node[2 * MAX_N], stack_depth[2 * MAX_N];
    size_t top = 1;
    stack_node[0] = active[0];
    stack_depth[0] = 0;
    while (top > 0) {
        --top;
        int node = stack_node[top], depth = stack_depth[top];
        if ((size_t)node < n) {
            depths[node] = depth;
        } else {
            stack_node[top] = right[node]; stack_depth[top++] = depth + 1;
            stack_node[top] = left[node]; stack_depth[top++] = depth + 1;
        }
    }

    /* Phase three: rebuild the ordered full tree from its leaf-depth code. */
    int ordered_left[2 * MAX_N - 1], ordered_right[2 * MAX_N - 1];
    int code_node[2 * MAX_N], code_depth[2 * MAX_N];
    for (size_t i = 0; i < 2 * n - 1; ++i) ordered_left[i] = ordered_right[i] = -1;
    size_t code_top = 0, next_ordered = n;
    for (size_t leaf = 0; leaf < n; ++leaf) {
        code_node[code_top] = (int)leaf;
        code_depth[code_top++] = depths[leaf];
        while (code_top >= 2 && code_depth[code_top - 1] == code_depth[code_top - 2]) {
            int level = code_depth[code_top - 1];
            if (level <= 0 || next_ordered >= 2 * n - 1) return -1;
            int l = code_node[code_top - 2], r = code_node[code_top - 1];
            ordered_left[next_ordered] = l;
            ordered_right[next_ordered] = r;
            code_top -= 2;
            code_node[code_top] = (int)next_ordered;
            code_depth[code_top++] = level - 1;
            ++next_ordered;
        }
    }
    if (code_top != 1 || code_depth[0] != 0 || next_ordered != 2 * n - 1) return -1;

    int64_t cost = 0;
    for (size_t i = 0; i < n; ++i) cost += input[i + 1] * depths[i];
    const size_t output_bytes = 8 * (n + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    put_i64_le(output, 0, cost);
    for (size_t i = 0; i < n; ++i) put_i64_le(output, 8 * (i + 1), depths[i]);
    return (int64_t)output_bytes;
}
