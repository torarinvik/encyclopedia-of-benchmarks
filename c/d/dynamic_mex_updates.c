#include <stddef.h>
#include <stdint.h>

#define MAX_N 32u
#define MAX_Q 32u
#define MAX_PARSEABLE_INPUT (2u + MAX_N + 2u * MAX_Q + 1u)
#define MAX_OUTPUT_BYTES (8u * MAX_Q)
#define VALUE_MIN (-1000)
#define VALUE_MAX 1000

static void tree_set(int *tree, size_t base, size_t value, int present)
{
    size_t node = base + value;
    tree[node] = present;
    node >>= 1u;
    while (node > 0u) {
        tree[node] = tree[2u * node] + tree[2u * node + 1u];
        node >>= 1u;
    }
}

static size_t find_mex(const int *tree, size_t base, size_t domain_size)
{
    size_t node = 1u, start = 0u, span = base;
    while (span > 1u) {
        const size_t half = span / 2u;
        const size_t left_width = start >= domain_size ? 0u :
            (domain_size - start < half ? domain_size - start : half);
        if ((size_t)tree[2u * node] < left_width) {
            node *= 2u;
            span = half;
        } else {
            node = 2u * node + 1u;
            start += half;
            span = half;
        }
    }
    return start;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0u; byte < 8u; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t dynamic_mex_updates(const int64_t *input, size_t length,
                            uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2u || length > MAX_PARSEABLE_INPUT) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (int64_t)MAX_N || q_value < 0 || q_value > (int64_t)MAX_Q)
        return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 2u + n + 2u * q) return -1;

    int64_t current[MAX_N];
    size_t update_index[MAX_Q];
    int64_t update_value[MAX_Q];
    for (size_t i = 0u; i < n; ++i) {
        const int64_t value = input[2u + i];
        if (value < VALUE_MIN || value > VALUE_MAX) return -1;
        current[i] = value;
    }
    size_t cursor = 2u + n;
    for (size_t i = 0u; i < q; ++i) {
        const int64_t index = input[cursor++];
        const int64_t value = input[cursor++];
        if (index < 0 || index >= n_value || value < VALUE_MIN || value > VALUE_MAX) return -1;
        update_index[i] = (size_t)index;
        update_value[i] = value;
    }

    const size_t needed = 8u * q;
    if (needed > 0u && (output == NULL || capacity < needed)) return -2;
    size_t base = 1u;
    while (base < n + 1u) base *= 2u;
    int frequencies[MAX_N + 1u] = {0};
    int tree[2u * (2u * MAX_N)] = {0};
    const size_t domain_size = n + 1u;
    for (size_t i = 0u; i < n; ++i)
        if (current[i] >= 0 && current[i] <= n_value) ++frequencies[(size_t)current[i]];
    for (size_t value = 0u; value < domain_size; ++value)
        tree[base + value] = frequencies[value] > 0 ? 1 : 0;
    for (size_t node = base; node-- > 1u;)
        tree[node] = tree[2u * node] + tree[2u * node + 1u];

    uint8_t staged[MAX_OUTPUT_BYTES];
    for (size_t op = 0u; op < q; ++op) {
        const size_t index = update_index[op];
        const int64_t old_value = current[index], new_value = update_value[op];
        if (old_value != new_value) {
            if (old_value >= 0 && old_value <= n_value) {
                const size_t old_index = (size_t)old_value;
                --frequencies[old_index];
                if (frequencies[old_index] == 0) tree_set(tree, base, old_index, 0);
            }
            if (new_value >= 0 && new_value <= n_value) {
                const size_t new_index = (size_t)new_value;
                if (frequencies[new_index] == 0) tree_set(tree, base, new_index, 1);
                ++frequencies[new_index];
            }
            current[index] = new_value;
        }
        write_i64_le(staged, 8u * op, (int64_t)find_mex(tree, base, domain_size));
    }
    for (size_t byte = 0u; byte < needed; ++byte) output[byte] = staged[byte];
    return (int64_t)needed;
}
