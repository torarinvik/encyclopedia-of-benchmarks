#include <stddef.h>
#include <stdint.h>

#define MAX_N 128
#define MAX_Q 256
#define MAX_INPUT_VALUES (2 * MAX_N + 1 + 3 * MAX_Q)
#define MAX_VALUE INT64_C(1000000)

static void fenwick_add(int64_t tree[MAX_N + 1], size_t n, size_t position, int64_t delta) {
    for (size_t index = position + 1; index <= n; index += index & (~index + 1))
        tree[index] += delta;
}

static int64_t fenwick_prefix(const int64_t tree[MAX_N + 1], size_t count) {
    int64_t total = 0;
    for (size_t index = count; index > 0; index -= index & (~index + 1))
        total += tree[index];
    return total;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t vertex_add_subtree_sum(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 2 * n + 1 + 3 * q) return -1;

    int64_t values[MAX_N], first_child[MAX_N], next_sibling[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        values[vertex] = input[2 + vertex];
        if (values[vertex] < 0 || values[vertex] > MAX_VALUE) return -1;
        first_child[vertex] = -1;
        next_sibling[vertex] = -1;
    }
    const size_t parent_start = 2 + n;
    for (size_t vertex = 1; vertex < n; ++vertex) {
        const int64_t parent_value = input[parent_start + vertex - 1];
        if (parent_value < 0 || (size_t)parent_value >= vertex) return -1;
        const size_t parent = (size_t)parent_value;
        next_sibling[vertex] = first_child[parent];
        first_child[parent] = (int64_t)vertex;
    }

    size_t tin[MAX_N], tout[MAX_N], stack_node[MAX_N];
    int64_t stack_next_child[MAX_N];
    size_t timer = 0, top = 1;
    stack_node[0] = 0;
    stack_next_child[0] = first_child[0];
    tin[0] = timer++;
    while (top > 0) {
        const size_t frame = top - 1;
        const int64_t child_value = stack_next_child[frame];
        if (child_value < 0) {
            tout[stack_node[frame]] = timer;
            --top;
            continue;
        }
        const size_t child = (size_t)child_value;
        stack_next_child[frame] = next_sibling[child];
        tin[child] = timer++;
        stack_node[top] = child;
        stack_next_child[top] = first_child[child];
        ++top;
    }

    int64_t fenwick[MAX_N + 1] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex)
        fenwick_add(fenwick, n, tin[vertex], values[vertex]);

    int64_t answers[MAX_Q];
    size_t answer_count = 0;
    const size_t operation_start = parent_start + n - 1;
    for (size_t index = 0; index < q; ++index) {
        const size_t offset = operation_start + 3 * index;
        const int64_t kind = input[offset], vertex_value = input[offset + 1];
        const int64_t operand = input[offset + 2];
        if (kind == 0) {
            if (vertex_value < 0 || (size_t)vertex_value >= n ||
                operand < 0 || operand > MAX_VALUE) return -1;
            const size_t vertex = (size_t)vertex_value;
            values[vertex] += operand;
            fenwick_add(fenwick, n, tin[vertex], operand);
        } else if (kind == 1) {
            if (vertex_value < 0 || (size_t)vertex_value >= n || operand != 0) return -1;
            const size_t vertex = (size_t)vertex_value;
            answers[answer_count++] = fenwick_prefix(fenwick, tout[vertex]) -
                fenwick_prefix(fenwick, tin[vertex]);
        } else return -1;
    }

    const size_t output_bytes = 8 * answer_count;
    if (output_bytes > 0 && (output == NULL || capacity < output_bytes)) return -2;
    for (size_t index = 0; index < answer_count; ++index)
        put_i64_le(output, 8 * index, answers[index]);
    return (int64_t)output_bytes;
}
