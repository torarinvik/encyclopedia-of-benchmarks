/*
Copyright (C) 1996 McGill University.
Copyright (C) 1996 McCAT System Group.
Copyright (C) 1996 ACAPS Benchmark Administrator
                   benadmin@acaps.cs.mcgill.ca

This program is free software; you can redistribute it and/or modify
it provided this copyright notice is maintained.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_NODES = 64, QUERY_COUNT = 100, HEADER_BYTES = 20, BITMAP_BYTES = 13, OUTPUT_BYTES = 33 };
enum { NONE = -1 };

typedef struct { int32_t value, left, right; } TreeNode;

static int tree_size(const TreeNode *tree, int32_t node) {
    if (node == NONE) return 0;
    return 1 + tree_size(tree, tree[node].left) + tree_size(tree, tree[node].right);
}

static double tree_sum(const TreeNode *tree, int32_t node) {
    if (node == NONE) return 0.0;
    return (double)tree[node].value + tree_sum(tree, tree[node].left) + tree_sum(tree, tree[node].right);
}

static int member_dfs(const TreeNode *tree, int32_t node, int32_t sought) {
    if (node == NONE) return 0;
    if (tree[node].value == sought) return 1;
    if (member_dfs(tree, tree[node].left, sought)) return 1;
    return member_dfs(tree, tree[node].right, sought);
}

static void put_u32_le(uint8_t *out, uint32_t value) {
    for (size_t i = 0; i < 4; ++i) out[i] = (uint8_t)(value >> (8u * i));
}

static void put_f64_le(uint8_t *out, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t i = 0; i < 8; ++i) out[i] = (uint8_t)(bits >> (8u * i));
}

int64_t mccat_bintr(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 103 || length > MAX_NODES + 102u) return -1;
    const int64_t node_count_value = input[0];
    if (node_count_value < 1 || node_count_value > MAX_NODES) return -1;
    const size_t node_count = (size_t)node_count_value;
    if (length != node_count + 102u || input[node_count + 1u] != QUERY_COUNT) return -1;
    for (size_t i = 0; i < node_count; ++i)
        if (input[i + 1u] == 0 || input[i + 1u] < -32768 || input[i + 1u] > 32767) return -1;
    for (size_t i = 0; i < QUERY_COUNT; ++i)
        if (input[node_count + 2u + i] == 0 || input[node_count + 2u + i] < -32768 || input[node_count + 2u + i] > 32767) return -1;
    if (output == NULL || capacity < OUTPUT_BYTES) return -2;

    TreeNode tree[MAX_NODES];
    int32_t root = NONE;
    int32_t used = 0;
    for (size_t i = 0; i < node_count; ++i) {
        const int32_t value = (int32_t)input[i + 1u];
        if (root == NONE) {
            root = 0;
            tree[0] = (TreeNode){value, NONE, NONE};
            used = 1;
            continue;
        }
        int32_t current = root;
        for (;;) {
            if (value == tree[current].value) break;
            int32_t *branch = value < tree[current].value ? &tree[current].left : &tree[current].right;
            if (*branch == NONE) {
                *branch = used;
                tree[used] = (TreeNode){value, NONE, NONE};
                ++used;
                break;
            }
            current = *branch;
        }
    }

    const int size = tree_size(tree, root);
    const double sum = tree_sum(tree, root);
    const double mean = sum / (double)size;
    uint8_t staged[OUTPUT_BYTES] = {0};
    put_u32_le(staged, (uint32_t)size);
    put_f64_le(staged + 4, sum);
    put_f64_le(staged + 12, mean);
    for (size_t i = 0; i < QUERY_COUNT; ++i)
        if (member_dfs(tree, root, (int32_t)input[node_count + 2u + i]))
            staged[HEADER_BYTES + i / 8u] |= (uint8_t)(1u << (i & 7u));
    memcpy(output, staged, OUTPUT_BYTES);
    return OUTPUT_BYTES;
}
