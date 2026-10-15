/* Flatten an indexed tree in place to its preorder right-child chain. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023
#define MAX_TREE_HEIGHT 512

static bool validate(const int64_t *nodes, size_t count, int64_t index,
                     size_t depth, bool *visited, size_t *seen) {
    if (index == -1) return true;
    if (index < 0 || (uint64_t)index >= count || depth > MAX_TREE_HEIGHT || visited[index]) return false;
    visited[index] = true;
    ++*seen;
    size_t offset = 3 * (size_t)index;
    int64_t value = nodes[offset], left = nodes[offset + 1], right = nodes[offset + 2];
    if (value < INT32_MIN || value > INT32_MAX || left < -1 || right < -1 ||
        (left >= 0 && (uint64_t)left >= count) || (right >= 0 && (uint64_t)right >= count)) return false;
    return validate(nodes, count, left, depth + 1, visited, seen) &&
           validate(nodes, count, right, depth + 1, visited, seen);
}

static void flatten(int64_t *nodes, int64_t index) {
    if (index == -1) return;
    size_t offset = 3 * (size_t)index;
    int64_t left = nodes[offset + 1];
    flatten(nodes, left);
    int64_t original_right = nodes[offset + 2];
    nodes[offset + 2] = left;
    nodes[offset + 1] = -1;
    int64_t tail = index;
    while (nodes[3 * (size_t)tail + 2] != -1) tail = nodes[3 * (size_t)tail + 2];
    nodes[3 * (size_t)tail + 2] = original_right;
    flatten(nodes, original_right);
}

static void store_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[offset + b] = (uint8_t)(bits >> (8 * b));
}

int64_t flatten_binarytree_to_linkedlist(const int64_t *values, size_t length,
                                         uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 1 || (length - 1) % 3 != 0 || length > 1 + 3 * MAX_NODE_COUNT) return -1;
    size_t count = (length - 1) / 3;
    int64_t root = values[0];
    if (count == 0) return root == -1 ? 0 : -1;
    if (root < 0 || (uint64_t)root >= count) return -1;
    int64_t nodes[3 * MAX_NODE_COUNT];
    bool visited[MAX_NODE_COUNT] = { false };
    size_t seen = 0;
    for (size_t i = 0; i < 3 * count; ++i) nodes[i] = values[i + 1];
    if (!validate(nodes, count, root, 1, visited, &seen) || seen != count) return -1;
    if (output == NULL || output_capacity < 24 * count) return -2;
    flatten(nodes, root);
    for (size_t i = 0; i < count; ++i) {
        store_i64(output, 24 * i, nodes[3 * i]);
        store_i64(output, 24 * i + 8, nodes[3 * i + 1]);
        store_i64(output, 24 * i + 16, nodes[3 * i + 2]);
    }
    return (int64_t)count;
}
