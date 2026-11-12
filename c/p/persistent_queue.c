#include <stddef.h>
#include <stdint.h>

#define MAX_Q 128u
#define TREE_BASE 128u
#define TREE_HEIGHT 7u
#define MAX_NODES (1u + MAX_Q * (TREE_HEIGHT + 1u))
#define MAX_VALID_INPUT (1u + 3u * MAX_Q)
#define MAX_PARSEABLE_INPUT (MAX_VALID_INPUT + 1u)
#define MAX_VALUE INT64_C(1000000000)

typedef struct { size_t left, right; int64_t value; } node_t;

static size_t set_value(node_t *nodes, size_t *used, size_t root,
                        size_t low, size_t high, size_t position, int64_t value)
{
    const size_t copy = (*used)++;
    nodes[copy] = nodes[root];
    if (high - low == 1u) {
        nodes[copy].value = value;
        return copy;
    }
    const size_t middle = low + (high - low) / 2u;
    if (position < middle)
        nodes[copy].left = set_value(nodes, used, nodes[root].left,
                                     low, middle, position, value);
    else
        nodes[copy].right = set_value(nodes, used, nodes[root].right,
                                      middle, high, position, value);
    return copy;
}

static int64_t get_value(const node_t *nodes, size_t root,
                         size_t low, size_t high, size_t position)
{
    if (high - low == 1u) return nodes[root].value;
    const size_t middle = low + (high - low) / 2u;
    return position < middle
        ? get_value(nodes, nodes[root].left, low, middle, position)
        : get_value(nodes, nodes[root].right, middle, high, position);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0u; byte < 8u; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t persistent_queue(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1u || length > MAX_PARSEABLE_INPUT) return -1;
    if (input[0] < 1 || input[0] > (int64_t)MAX_Q) return -1;
    const size_t q = (size_t)input[0];
    int64_t kind[MAX_Q], parent[MAX_Q], value[MAX_Q];
    size_t version_head[MAX_Q + 1u] = {0u};
    size_t version_tail[MAX_Q + 1u] = {0u};
    size_t version_size[MAX_Q + 1u] = {0u};
    size_t cursor = 1u, pop_count = 0u;

    for (size_t operation = 0u; operation < q; ++operation) {
        if (cursor + 2u > length) return -1;
        kind[operation] = input[cursor++];
        parent[operation] = input[cursor++];
        if ((kind[operation] != 0 && kind[operation] != 1) ||
            parent[operation] < -1 || parent[operation] >= (int64_t)operation)
            return -1;
        const size_t base = (size_t)(parent[operation] + 1);
        if (kind[operation] == 0) {
            if (cursor >= length) return -1;
            value[operation] = input[cursor++];
            if (value[operation] < 0 || value[operation] > MAX_VALUE ||
                version_tail[base] >= TREE_BASE) return -1;
            version_head[operation + 1u] = version_head[base];
            version_tail[operation + 1u] = version_tail[base] + 1u;
            version_size[operation + 1u] = version_size[base] + 1u;
        } else {
            if (version_size[base] == 0u) return -1;
            version_head[operation + 1u] = version_head[base] + 1u;
            version_tail[operation + 1u] = version_tail[base];
            version_size[operation + 1u] = version_size[base] - 1u;
            ++pop_count;
        }
    }
    if (cursor != length) return -1;

    const size_t output_bytes = 8u * pop_count;
    if (output_bytes != 0u && (output == NULL || capacity < output_bytes)) return -2;

    node_t nodes[MAX_NODES] = {{0u, 0u, 0}};
    size_t roots[MAX_Q + 1u] = {0u};
    size_t answers[MAX_Q];
    size_t answer_count = 0u, used = 1u;
    for (size_t operation = 0u; operation < q; ++operation) {
        const size_t base = (size_t)(parent[operation] + 1);
        const size_t version = operation + 1u;
        if (kind[operation] == 0) {
            roots[version] = set_value(nodes, &used, roots[base], 0u, TREE_BASE,
                                       version_tail[base], value[operation]);
        } else {
            answers[answer_count++] = (size_t)get_value(
                nodes, roots[base], 0u, TREE_BASE, version_head[base]);
            roots[version] = roots[base];
        }
    }
    for (size_t i = 0u; i < answer_count; ++i)
        store_i64_le(output, 8u * i, (int64_t)answers[i]);
    return (int64_t)output_bytes;
}
