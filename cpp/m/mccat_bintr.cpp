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

#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_nodes = 64, query_count = 100, output_bytes = 33;
struct TreeNode { std::int32_t value, left, right; };

int tree_size(const TreeNode *tree, std::int32_t node) {
    if (node < 0) return 0;
    return 1 + tree_size(tree, tree[node].left) + tree_size(tree, tree[node].right);
}
double tree_sum(const TreeNode *tree, std::int32_t node) {
    if (node < 0) return 0.0;
    return static_cast<double>(tree[node].value) + tree_sum(tree, tree[node].left) + tree_sum(tree, tree[node].right);
}
bool member_dfs(const TreeNode *tree, std::int32_t node, std::int32_t sought) {
    if (node < 0) return false;
    if (tree[node].value == sought) return true;
    if (member_dfs(tree, tree[node].left, sought)) return true;
    return member_dfs(tree, tree[node].right, sought);
}
void put_u32_le(std::uint8_t *out, std::uint32_t value) {
    for (std::size_t i = 0; i < 4; ++i) out[i] = static_cast<std::uint8_t>(value >> (8 * i));
}
void put_f64_le(std::uint8_t *out, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t i = 0; i < 8; ++i) out[i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

extern "C" std::int64_t mccat_bintr(const std::int64_t *input, std::size_t length,
                                     std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 103 || length > max_nodes + 102) return -1;
    const auto node_count_value = input[0];
    if (node_count_value < 1 || node_count_value > static_cast<std::int64_t>(max_nodes)) return -1;
    const auto node_count = static_cast<std::size_t>(node_count_value);
    if (length != node_count + 102 || input[node_count + 1] != static_cast<std::int64_t>(query_count)) return -1;
    for (std::size_t i = 0; i < node_count; ++i)
        if (input[i + 1] == 0 || input[i + 1] < -32768 || input[i + 1] > 32767) return -1;
    for (std::size_t i = 0; i < query_count; ++i)
        if (input[node_count + 2 + i] == 0 || input[node_count + 2 + i] < -32768 || input[node_count + 2 + i] > 32767) return -1;
    if (output == nullptr || capacity < output_bytes) return -2;

    TreeNode tree[max_nodes];
    std::int32_t root = -1;
    std::int32_t used = 0;
    for (std::size_t i = 0; i < node_count; ++i) {
        const auto value = static_cast<std::int32_t>(input[i + 1]);
        if (root < 0) {
            root = 0;
            tree[0] = {value, -1, -1};
            used = 1;
            continue;
        }
        std::int32_t current = root;
        for (;;) {
            if (value == tree[current].value) break;
            auto &branch = value < tree[current].value ? tree[current].left : tree[current].right;
            if (branch < 0) {
                branch = used;
                tree[used] = {value, -1, -1};
                ++used;
                break;
            }
            current = branch;
        }
    }

    const int size = tree_size(tree, root);
    const double sum = tree_sum(tree, root);
    const double mean = sum / static_cast<double>(size);
    std::uint8_t staged[output_bytes]{};
    put_u32_le(staged, static_cast<std::uint32_t>(size));
    put_f64_le(staged + 4, sum);
    put_f64_le(staged + 12, mean);
    for (std::size_t i = 0; i < query_count; ++i)
        if (member_dfs(tree, root, static_cast<std::int32_t>(input[node_count + 2 + i])))
            staged[20 + i / 8] |= static_cast<std::uint8_t>(1u << (i & 7));
    std::memcpy(output, staged, output_bytes);
    return output_bytes;
}
