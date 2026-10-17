#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_text_length = 64;
constexpr std::size_t max_valid_input_length = 1 + max_text_length;
constexpr std::size_t max_parseable_input_length = max_valid_input_length + 1;
constexpr std::size_t max_tree_nodes = 1 + 2 * max_text_length;
constexpr std::size_t max_tree_edges = 2 * max_text_length;
constexpr std::size_t max_output_bytes =
    max_text_length * (max_text_length + 1) / 2 + 48 * max_text_length + 24;

struct TreeNode {
    std::size_t label_start;
    std::size_t label_length;
    std::size_t first_edge;
    std::size_t last_edge;
    std::size_t child_count;
};

bool write_u64_le(std::uint8_t* buffer, std::size_t capacity,
                  std::size_t& offset, std::uint64_t value) noexcept
{
    if (offset > capacity || capacity - offset < 8) return false;
    for (std::size_t byte = 0; byte < 8; ++byte) {
        buffer[offset++] = static_cast<std::uint8_t>(value & UINT64_C(0xff));
        value >>= 8;
    }
    return true;
}

bool append_child_edge(TreeNode* nodes, std::size_t* edge_target,
                       std::size_t* next_edge, std::size_t& edge_count,
                       std::size_t parent, std::size_t child) noexcept
{
    if (edge_count >= max_tree_edges) return false;
    const std::size_t edge = ++edge_count;
    edge_target[edge] = child;
    next_edge[edge] = 0;
    if (nodes[parent].child_count == 0) {
        nodes[parent].first_edge = edge;
    } else {
        next_edge[nodes[parent].last_edge] = edge;
    }
    nodes[parent].last_edge = edge;
    ++nodes[parent].child_count;
    return true;
}
} // namespace

extern "C" std::int64_t suffix_tree_construct(const std::int64_t* input,
                                               std::size_t input_length,
                                               std::uint8_t* output,
                                               std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 1 ||
        input_length > max_parseable_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text_length)) return -1;
    const std::size_t text_length = static_cast<std::size_t>(input[0]);
    if (input_length != 1 + text_length) return -1;
    for (std::size_t i = 0; i < text_length; ++i) {
        if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    }

    TreeNode nodes[max_tree_nodes] = {};
    std::size_t edge_target[max_tree_edges + 1] = {};
    std::size_t next_edge[max_tree_edges + 1] = {};
    std::size_t node_count = 1;
    std::size_t edge_count = 0;

    for (std::size_t suffix_start = 0; suffix_start < text_length; ++suffix_start) {
        const std::size_t suffix_length = text_length - suffix_start;
        std::size_t node = 0;
        std::size_t offset = 0;
        while (offset < suffix_length) {
            const std::int64_t first_code = input[1 + suffix_start + offset];
            std::size_t edge = nodes[node].first_edge;
            while (edge != 0 && input[1 + nodes[edge_target[edge]].label_start] != first_code) {
                edge = next_edge[edge];
            }

            if (edge == 0) {
                if (node_count >= max_tree_nodes) return -1;
                const std::size_t leaf = node_count++;
                nodes[leaf].label_start = suffix_start + offset;
                nodes[leaf].label_length = suffix_length - offset;
                if (!append_child_edge(nodes, edge_target, next_edge,
                                       edge_count, node, leaf)) return -1;
                break;
            }

            std::size_t child = edge_target[edge];
            const std::size_t old_label_start = nodes[child].label_start;
            const std::size_t old_label_length = nodes[child].label_length;
            std::size_t common = 0;
            while (common < old_label_length) {
                if (offset + common >= suffix_length ||
                    input[1 + suffix_start + offset + common] !=
                        input[1 + old_label_start + common]) {
                    if (node_count >= max_tree_nodes) return -1;
                    const std::size_t split_node = node_count++;
                    nodes[split_node].label_start = old_label_start;
                    nodes[split_node].label_length = common;
                    nodes[child].label_start = old_label_start + common;
                    nodes[child].label_length = old_label_length - common;
                    edge_target[edge] = split_node;
                    if (!append_child_edge(nodes, edge_target, next_edge,
                                           edge_count, split_node, child)) return -1;
                    child = split_node;
                    break;
                }
                ++common;
            }

            offset += common;
            node = child;
        }
    }

    std::uint8_t staged[max_output_bytes] = {};
    std::size_t staged_length = 0;
    if (!write_u64_le(staged, max_output_bytes, staged_length,
                      static_cast<std::uint64_t>(node_count))) return -1;
    for (std::size_t node = 0; node < node_count; ++node) {
        if (!write_u64_le(staged, max_output_bytes, staged_length,
                          static_cast<std::uint64_t>(nodes[node].label_length))) return -1;
        if (nodes[node].label_length > max_output_bytes - staged_length) return -1;
        for (std::size_t byte = 0; byte < nodes[node].label_length; ++byte) {
            staged[staged_length + byte] =
                static_cast<std::uint8_t>(input[1 + nodes[node].label_start + byte]);
        }
        staged_length += nodes[node].label_length;
        if (!write_u64_le(staged, max_output_bytes, staged_length,
                          static_cast<std::uint64_t>(nodes[node].child_count))) return -1;
        std::size_t edge = nodes[node].first_edge;
        while (edge != 0) {
            if (!write_u64_le(staged, max_output_bytes, staged_length,
                              static_cast<std::uint64_t>(edge_target[edge]))) return -1;
            edge = next_edge[edge];
        }
    }

    if (output == nullptr || output_capacity < staged_length) return -2;
    std::memcpy(output, staged, staged_length);
    return static_cast<std::int64_t>(staged_length);
}
