#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 64
#define MAX_LEVELS 6
#define MAX_INPUT_VALUES (2 + MAX_N + 3 * MAX_Q)
#define MODULUS INT64_C(998244353)

static int64_t normalize(int64_t value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static size_t find_root(size_t parent[MAX_LEVELS][MAX_N], size_t level, size_t item) {
    if (parent[level][item] != item)
        parent[level][item] = find_root(parent, level, parent[level][item]);
    return parent[level][item];
}

static void merge_inner(size_t level, size_t left, size_t right,
    size_t parent[MAX_LEVELS][MAX_N], size_t set_size[MAX_LEVELS][MAX_N],
    int64_t *component_weight, int64_t *pair_sum) {
    size_t root_left = find_root(parent, level, left);
    size_t root_right = find_root(parent, level, right);
    if (root_left == root_right) return;
    if (set_size[level][root_left] < set_size[level][root_right]) {
        const size_t temporary = root_left;
        root_left = root_right;
        root_right = temporary;
    }
    parent[level][root_right] = root_left;
    set_size[level][root_left] += set_size[level][root_right];
    if (level == 0) {
        *pair_sum = normalize(*pair_sum + component_weight[root_left] * component_weight[root_right]);
        component_weight[root_left] = normalize(component_weight[root_left] + component_weight[root_right]);
        return;
    }
    const size_t half = (size_t)1 << (level - 1);
    merge_inner(level - 1, left, right, parent, set_size, component_weight, pair_sum);
    merge_inner(level - 1, left + half, right + half, parent, set_size, component_weight, pair_sum);
}

static size_t floor_log2(size_t value) {
    size_t level = 0;
    while (value > 1) { value >>= 1; ++level; }
    return level;
}

static void merge_ranges(size_t length, size_t left, size_t right,
    size_t parent[MAX_LEVELS][MAX_N], size_t set_size[MAX_LEVELS][MAX_N],
    int64_t *component_weight, int64_t *pair_sum) {
    if (length == 0) return;
    const size_t block = (size_t)1 << floor_log2(length - 1);
    const size_t largest_level = floor_log2(length - 1);
    merge_inner(largest_level, left, right, parent, set_size, component_weight, pair_sum);
    merge_inner(largest_level, left + length - block, right + length - block,
                parent, set_size, component_weight, pair_sum);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t range_parallel_unionfind(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 6 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 2 + n + 3 * q) return -1;
    for (size_t item = 0; item < n; ++item)
        if (input[2 + item] < 0 || input[2 + item] >= MODULUS) return -1;
    const size_t operations_at = 2 + n;
    for (size_t operation = 0; operation < q; ++operation) {
        const size_t position = operations_at + 3 * operation;
        const int64_t range_length = input[position], left = input[position + 1], right = input[position + 2];
        if (range_length < 0 || range_length > n_value || left < 0 || right < 0 ||
            left > n_value - range_length || right > n_value - range_length) return -1;
    }
    const size_t required = 8 * q;
    if (output == NULL || capacity < required) return -2;

    size_t parent[MAX_LEVELS][MAX_N], set_size[MAX_LEVELS][MAX_N];
    int64_t component_weight[MAX_N];
    for (size_t level = 0; level < MAX_LEVELS; ++level) {
        const size_t block = (size_t)1 << level;
        if (block > n) break;
        const size_t positions = n - block + 1;
        for (size_t start = 0; start < positions; ++start) {
            parent[level][start] = start;
            set_size[level][start] = 1;
        }
    }
    for (size_t item = 0; item < n; ++item) component_weight[item] = input[2 + item];
    int64_t pair_sum = 0;
    for (size_t operation = 0; operation < q; ++operation) {
        const size_t position = operations_at + 3 * operation;
        const size_t range_length = (size_t)input[position];
        const size_t left = (size_t)input[position + 1], right = (size_t)input[position + 2];
        merge_ranges(range_length, left, right, parent, set_size, component_weight, &pair_sum);
        store_i64_le(output, 8 * operation, pair_sum);
    }
    return (int64_t)required;
}
