// Copy an indexed tree, recursively swap its children, and serialize the result.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 1023;
constexpr std::size_t max_tree_height = 512;

bool validate_subtree(const std::int64_t *values,
                      std::size_t node_count, std::int64_t index, std::size_t depth,
                      std::array<bool, max_node_count> &visited) {
    if (index == -1) return true;
    if (index < 0 || static_cast<std::uint64_t>(index) >= node_count ||
        depth > max_tree_height || visited[static_cast<std::size_t>(index)]) return false;
    const auto node = static_cast<std::size_t>(index);
    visited[node] = true;
    const auto offset = 1 + node * 3;
    const auto value = values[offset], left = values[offset + 1], right = values[offset + 2];
    if (value < INT32_MIN || value > INT32_MAX || left < -1 || right < -1 ||
        (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
        (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return false;
    return validate_subtree(values, node_count, left, depth + 1, visited) &&
           validate_subtree(values, node_count, right, depth + 1, visited);
}

void store_i64_little_endian(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

void emit_mirrored_subtree(const std::int64_t *values, std::int64_t index, std::uint8_t *output) {
    if (index == -1) return;
    const auto input_offset = 1 + static_cast<std::size_t>(index) * 3;
    const auto output_offset = 24 * static_cast<std::size_t>(index);
    const auto left = values[input_offset + 1], right = values[input_offset + 2];
    store_i64_little_endian(output, output_offset, values[input_offset]);
    store_i64_little_endian(output, output_offset + 8, right);
    store_i64_little_endian(output, output_offset + 16, left);
    emit_mirrored_subtree(values, right, output);
    emit_mirrored_subtree(values, left, output);
}
}

extern "C" std::int64_t invert_binary_tree(const std::int64_t *values, std::size_t length,
                                             std::uint8_t *output,
                                             std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 1 || (length - 1) % 3 != 0 ||
        length > 1 + 3 * max_node_count) return -1;
    const auto node_count = (length - 1) / 3;
    const auto root = values[0];
    if (node_count == 0) return root == -1 ? 0 : -1;
    if (root < 0 || static_cast<std::uint64_t>(root) >= node_count) return -1;

    std::array<bool, max_node_count> visited{};
    if (!validate_subtree(values, node_count, root, 1, visited)) return -1;
    for (std::size_t index = 0; index < node_count; ++index)
        if (!visited[index]) return -1;

    const auto output_length = 24 * node_count;
    if (output == nullptr || output_capacity < output_length) return -2;
    emit_mirrored_subtree(values, root, output);
    return static_cast<std::int64_t>(node_count);
}
