#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_TEXT_LENGTH 64u
#define MAX_VALID_INPUT_LENGTH (1u + MAX_TEXT_LENGTH)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1u)
#define MAX_TREE_NODES (1u + 2u * MAX_TEXT_LENGTH)
#define MAX_TREE_EDGES (2u * MAX_TEXT_LENGTH)
#define MAX_OUTPUT_BYTES (MAX_TEXT_LENGTH * (MAX_TEXT_LENGTH + 1u) / 2u + \
                          48u * MAX_TEXT_LENGTH + 24u)

typedef struct {
    size_t label_start;
    size_t label_length;
    size_t first_edge;
    size_t last_edge;
    size_t child_count;
} TreeNode;

static int write_u64_le(uint8_t *buffer, size_t capacity, size_t *offset,
                        uint64_t value)
{
    if (*offset > capacity || capacity - *offset < 8u) return 0;
    for (size_t byte = 0u; byte < 8u; ++byte) {
        buffer[(*offset)++] = (uint8_t)(value & UINT64_C(0xff));
        value >>= 8u;
    }
    return 1;
}

static int append_child_edge(TreeNode *nodes, size_t *edge_target,
                             size_t *next_edge, size_t *edge_count,
                             size_t parent, size_t child)
{
    if (*edge_count >= MAX_TREE_EDGES) return 0;
    const size_t edge = ++(*edge_count);
    edge_target[edge] = child;
    next_edge[edge] = 0u;
    if (nodes[parent].child_count == 0u) {
        nodes[parent].first_edge = edge;
    } else {
        next_edge[nodes[parent].last_edge] = edge;
    }
    nodes[parent].last_edge = edge;
    ++nodes[parent].child_count;
    return 1;
}

int64_t suffix_tree_construct(const int64_t *input, size_t input_length,
                              uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1u ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (int64_t)MAX_TEXT_LENGTH) return -1;
    const size_t text_length = (size_t)input[0];
    if (input_length != 1u + text_length) return -1;
    for (size_t i = 0u; i < text_length; ++i) {
        if (input[1u + i] < 0 || input[1u + i] > 127) return -1;
    }

    TreeNode nodes[MAX_TREE_NODES] = {0};
    size_t edge_target[MAX_TREE_EDGES + 1u] = {0u};
    size_t next_edge[MAX_TREE_EDGES + 1u] = {0u};
    size_t node_count = 1u; /* The empty-label root is node zero. */
    size_t edge_count = 0u;

    for (size_t suffix_start = 0u; suffix_start < text_length; ++suffix_start) {
        const size_t suffix_length = text_length - suffix_start;
        size_t node = 0u;
        size_t offset = 0u;
        while (offset < suffix_length) {
            const int64_t first_code = input[1u + suffix_start + offset];
            size_t edge = nodes[node].first_edge;
            while (edge != 0u &&
                   input[1u + nodes[edge_target[edge]].label_start] != first_code) {
                edge = next_edge[edge];
            }

            if (edge == 0u) {
                if (node_count >= MAX_TREE_NODES) return -1;
                const size_t leaf = node_count++;
                nodes[leaf].label_start = suffix_start + offset;
                nodes[leaf].label_length = suffix_length - offset;
                if (!append_child_edge(nodes, edge_target, next_edge,
                                       &edge_count, node, leaf)) return -1;
                break; /* The pinned source returns after adding a new edge. */
            }

            size_t child = edge_target[edge];
            const size_t old_label_start = nodes[child].label_start;
            const size_t old_label_length = nodes[child].label_length;
            size_t common = 0u;
            while (common < old_label_length) {
                if (offset + common >= suffix_length ||
                    input[1u + suffix_start + offset + common] !=
                        input[1u + old_label_start + common]) {
                    if (node_count >= MAX_TREE_NODES) return -1;
                    const size_t split_node = node_count++;
                    nodes[split_node].label_start = old_label_start;
                    nodes[split_node].label_length = common;
                    nodes[child].label_start = old_label_start + common;
                    nodes[child].label_length = old_label_length - common;
                    edge_target[edge] = split_node;
                    if (!append_child_edge(nodes, edge_target, next_edge,
                                           &edge_count, split_node, child)) return -1;
                    child = split_node;
                    break;
                }
                ++common;
            }

            offset += common;
            node = child;
        }
    }

    uint8_t staged[MAX_OUTPUT_BYTES];
    size_t staged_length = 0u;
    if (!write_u64_le(staged, MAX_OUTPUT_BYTES, &staged_length,
                      (uint64_t)node_count)) return -1;
    for (size_t node = 0u; node < node_count; ++node) {
        const size_t label_length = nodes[node].label_length;
        if (!write_u64_le(staged, MAX_OUTPUT_BYTES, &staged_length,
                          (uint64_t)label_length)) return -1;
        if (label_length > MAX_OUTPUT_BYTES - staged_length) return -1;
        for (size_t byte = 0u; byte < label_length; ++byte) {
            staged[staged_length++] =
                (uint8_t)input[1u + nodes[node].label_start + byte];
        }
        if (!write_u64_le(staged, MAX_OUTPUT_BYTES, &staged_length,
                          (uint64_t)nodes[node].child_count)) return -1;
        size_t edge = nodes[node].first_edge;
        while (edge != 0u) {
            if (!write_u64_le(staged, MAX_OUTPUT_BYTES, &staged_length,
                              (uint64_t)edge_target[edge])) return -1;
            edge = next_edge[edge];
        }
    }

    if (output == NULL || output_capacity < staged_length) return -2;
    memcpy(output, staged, staged_length);
    return (int64_t)staged_length;
}
