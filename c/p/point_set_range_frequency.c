#include <stddef.h>
#include <stdint.h>

#define MAX_N 64u
#define MAX_Q 64u
#define MAX_VALUES (MAX_N + MAX_Q)
#define STRIDE (MAX_N + 1u)
#define MAX_TREE (MAX_VALUES * STRIDE)
#define MAX_PARSEABLE_INPUT (2u + MAX_N + 4u * MAX_Q + 1u)
#define MAX_OUTPUT_BYTES (8u * MAX_Q)
#define MAX_VALUE INT64_C(1000000)

typedef struct { int64_t kind, a, b, c; } operation_t;

static size_t lowbit(size_t value) { return value & (~value + 1u); }

static size_t lower_bound_i64(const int64_t *values, size_t count, int64_t target)
{
    size_t left = 0u, right = count;
    while (left < right) {
        const size_t middle = left + (right - left) / 2u;
        if (values[middle] < target) left = middle + 1u;
        else right = middle;
    }
    return left;
}

static size_t sort_unique(int64_t *values, size_t count)
{
    for (size_t i = 1u; i < count; ++i) {
        const int64_t value = values[i];
        size_t position = i;
        while (position > 0u && values[position - 1u] > value) {
            values[position] = values[position - 1u];
            --position;
        }
        values[position] = value;
    }
    size_t unique_count = 0u;
    for (size_t i = 0u; i < count; ++i) {
        if (unique_count == 0u || values[i] != values[unique_count - 1u])
            values[unique_count++] = values[i];
    }
    return unique_count;
}

static void fenwick_add(int64_t *tree, size_t value_id, size_t position,
                        size_t n, int64_t delta)
{
    size_t index = position + 1u;
    const size_t row = value_id * STRIDE;
    while (index <= n) {
        tree[row + index] += delta;
        index += lowbit(index);
    }
}

static int64_t fenwick_prefix(const int64_t *tree, size_t value_id, size_t count)
{
    int64_t total = 0;
    size_t index = count;
    const size_t row = value_id * STRIDE;
    while (index > 0u) {
        total += tree[row + index];
        index -= lowbit(index);
    }
    return total;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0u; byte < 8u; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t point_set_range_frequency(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2u || length > MAX_PARSEABLE_INPUT) return -1;
    if (input[0] < 1 || input[0] > (int64_t)MAX_N ||
        input[1] < 0 || input[1] > (int64_t)MAX_Q) return -1;
    const size_t n = (size_t)input[0], q = (size_t)input[1];
    if (2u + n > length) return -1;
    int64_t values[MAX_VALUES];
    int64_t initial[MAX_N];
    operation_t operations[MAX_Q];
    size_t value_count = 0u;
    for (size_t i = 0u; i < n; ++i) {
        const int64_t value = input[2u + i];
        if (value < 0 || value > MAX_VALUE) return -1;
        initial[i] = value;
        values[value_count++] = value;
    }
    size_t cursor = 2u + n, query_count = 0u;
    for (size_t i = 0u; i < q; ++i) {
        if (cursor >= length) return -1;
        const int64_t kind = input[cursor++];
        if (kind == 0) {
            if (cursor + 2u > length) return -1;
            const int64_t index = input[cursor], value = input[cursor + 1u];
            cursor += 2u;
            if (index < 0 || index >= (int64_t)n || value < 0 || value > MAX_VALUE) return -1;
            operations[i] = (operation_t){kind, index, value, 0};
            values[value_count++] = value;
        } else if (kind == 1) {
            if (cursor + 3u > length) return -1;
            const int64_t left = input[cursor], right = input[cursor + 1u], value = input[cursor + 2u];
            cursor += 3u;
            if (left < 0 || left > right || right > (int64_t)n || value < 0 || value > MAX_VALUE) return -1;
            operations[i] = (operation_t){kind, left, right, value};
            ++query_count;
        } else return -1;
    }
    if (cursor != length) return -1;
    const size_t output_bytes = 8u * query_count;
    if (output_bytes > 0u && (output == NULL || capacity < output_bytes)) return -2;

    const size_t unique_count = sort_unique(values, value_count);
    int64_t tree[MAX_TREE] = {0};
    size_t current[MAX_N];
    for (size_t i = 0u; i < n; ++i) {
        current[i] = lower_bound_i64(values, unique_count, initial[i]);
        fenwick_add(tree, current[i], i, n, 1);
    }
    size_t answer = 0u;
    for (size_t i = 0u; i < q; ++i) {
        const operation_t operation = operations[i];
        if (operation.kind == 0) {
            const size_t index = (size_t)operation.a;
            const size_t next = lower_bound_i64(values, unique_count, operation.b);
            if (current[index] != next) {
                fenwick_add(tree, current[index], index, n, -1);
                fenwick_add(tree, next, index, n, 1);
                current[index] = next;
            }
        } else {
            const size_t id = lower_bound_i64(values, unique_count, operation.c);
            int64_t count = 0;
            if (id < unique_count && values[id] == operation.c)
                count = fenwick_prefix(tree, id, (size_t)operation.b) -
                        fenwick_prefix(tree, id, (size_t)operation.a);
            store_i64_le(output, 8u * answer++, count);
        }
    }
    return (int64_t)output_bytes;
}
