/* Copy an indexed tree, recursively swap its children, and serialize the result. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023
#define MAX_TREE_HEIGHT 512

static bool validate_subtree(const int64_t *values, size_t node_count, int64_t index,
                             size_t depth, bool *visited, size_t *visited_count)
{
    if (index == -1) return true;
    if (index < 0 || (uint64_t)index >= node_count || depth > MAX_TREE_HEIGHT || visited[index])
        return false;
    visited[index] = true;
    ++*visited_count;
    const size_t offset = 1 + (size_t)index * 3;
    const int64_t value = values[offset];
    const int64_t left = values[offset + 1];
    const int64_t right = values[offset + 2];
    if (value < INT32_MIN || value > INT32_MAX || left < -1 || right < -1 ||
        (left >= 0 && (uint64_t)left >= node_count) ||
        (right >= 0 && (uint64_t)right >= node_count)) return false;
    return validate_subtree(values, node_count, left, depth + 1, visited, visited_count) &&
           validate_subtree(values, node_count, right, depth + 1, visited, visited_count);
}

static void store_i64_little_endian(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void emit_mirrored_subtree(const int64_t *values, int64_t index, uint8_t *output)
{
    if (index == -1) return;
    const size_t input_offset = 1 + (size_t)index * 3;
    const size_t output_offset = 24 * (size_t)index;
    const int64_t left = values[input_offset + 1];
    const int64_t right = values[input_offset + 2];
    store_i64_little_endian(output, output_offset, values[input_offset]);
    store_i64_little_endian(output, output_offset + 8, right);
    store_i64_little_endian(output, output_offset + 16, left);
    emit_mirrored_subtree(values, right, output);
    emit_mirrored_subtree(values, left, output);
}

int64_t invert_binary_tree(const int64_t *values, size_t length,
                           uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || (length - 1) % 3 != 0 ||
        length > 1 + 3 * MAX_NODE_COUNT) return -1;
    const size_t node_count = (length - 1) / 3;
    const int64_t root = values[0];
    if (node_count == 0) return root == -1 ? 0 : -1;
    if (root < 0 || (uint64_t)root >= node_count) return -1;

    bool visited[MAX_NODE_COUNT] = { false };
    size_t visited_count = 0;
    if (!validate_subtree(values, node_count, root, 1, visited, &visited_count) ||
        visited_count != node_count) return -1;

    const size_t output_length = 3 * node_count * 8;
    if (output == NULL || output_capacity < output_length) return -2;
    emit_mirrored_subtree(values, root, output);
    return (int64_t)node_count;
}
