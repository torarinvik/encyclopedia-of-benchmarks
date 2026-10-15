// Flatten an indexed tree in place to its preorder right-child chain.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 1023, max_height = 512;
bool validate(const std::int64_t *nodes, std::size_t count, std::int64_t index,
              std::size_t depth, std::array<bool, max_nodes> &visited, std::size_t &seen) {
    if (index == -1) return true;
    if (index < 0 || static_cast<std::uint64_t>(index) >= count || depth > max_height || visited[index]) return false;
    visited[index] = true; ++seen;
    const auto off = 3 * static_cast<std::size_t>(index);
    const auto value = nodes[off], left = nodes[off + 1], right = nodes[off + 2];
    if (value < INT32_MIN || value > INT32_MAX || left < -1 || right < -1 ||
        (left >= 0 && static_cast<std::uint64_t>(left) >= count) ||
        (right >= 0 && static_cast<std::uint64_t>(right) >= count)) return false;
    return validate(nodes, count, left, depth + 1, visited, seen) &&
           validate(nodes, count, right, depth + 1, visited, seen);
}
void flatten(std::int64_t *nodes, std::int64_t index) {
    if (index == -1) return;
    const auto off = 3 * static_cast<std::size_t>(index);
    const auto left = nodes[off + 1];
    flatten(nodes, left);
    const auto original_right = nodes[off + 2];
    nodes[off + 2] = left; nodes[off + 1] = -1;
    auto tail = index;
    while (nodes[3 * static_cast<std::size_t>(tail) + 2] != -1)
        tail = nodes[3 * static_cast<std::size_t>(tail) + 2];
    nodes[3 * static_cast<std::size_t>(tail) + 2] = original_right;
    flatten(nodes, original_right);
}
void store(std::uint8_t *out, std::size_t off, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[off + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}
extern "C" std::int64_t flatten_binarytree_to_linkedlist(const std::int64_t *values,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (!values || length < 1 || (length - 1) % 3 || length > 1 + 3 * max_nodes) return -1;
    const auto count = (length - 1) / 3, root = values[0];
    if (!count) return root == -1 ? 0 : -1;
    if (root < 0 || static_cast<std::uint64_t>(root) >= count) return -1;
    std::array<std::int64_t, 3 * max_nodes> nodes{};
    for (std::size_t i = 0; i < 3 * count; ++i) nodes[i] = values[i + 1];
    std::array<bool, max_nodes> visited{}; std::size_t seen = 0;
    if (!validate(nodes.data(), count, root, 1, visited, seen) || seen != count) return -1;
    if (!output || capacity < 24 * count) return -2;
    flatten(nodes.data(), root);
    for (std::size_t i = 0; i < count; ++i) {
        store(output, 24 * i, nodes[3 * i]); store(output, 24 * i + 8, nodes[3 * i + 1]);
        store(output, 24 * i + 16, nodes[3 * i + 2]);
    }
    return static_cast<std::int64_t>(count);
}
