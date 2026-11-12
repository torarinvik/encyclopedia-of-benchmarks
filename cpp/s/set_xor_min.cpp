#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_q = 64;
constexpr std::size_t max_bits = 30;
constexpr std::size_t max_nodes = 1 + max_bits * max_q;
constexpr std::size_t max_input_values = 1 + 2 * max_q;

std::size_t find_or_create_child(std::array<std::array<std::int32_t, 2>, max_nodes> &children,
    std::size_t &node_count, std::size_t node, std::size_t direction) noexcept {
    auto &child = children[node][direction];
    if (child < 0) {
        child = static_cast<std::int32_t>(node_count++);
        children[static_cast<std::size_t>(child)] = {-1, -1};
    }
    return static_cast<std::size_t>(child);
}

void insert_value(std::array<std::array<std::int32_t, 2>, max_nodes> &children,
    std::array<std::int32_t, max_nodes> &count, std::size_t &node_count,
    std::uint32_t value) noexcept {
    std::array<std::size_t, max_bits + 1> path{};
    std::size_t node = 0;
    for (std::size_t depth = 0; depth < max_bits; ++depth) {
        const auto bit = max_bits - 1 - depth;
        node = find_or_create_child(children, node_count, node, (value >> bit) & 1u);
        path[depth + 1] = node;
    }
    if (count[node] != 0) return;
    for (const auto position : path) ++count[position];
}

void remove_value(const std::array<std::array<std::int32_t, 2>, max_nodes> &children,
    std::array<std::int32_t, max_nodes> &count, std::uint32_t value) noexcept {
    std::array<std::size_t, max_bits + 1> path{};
    std::size_t node = 0;
    for (std::size_t depth = 0; depth < max_bits; ++depth) {
        const auto bit = max_bits - 1 - depth;
        const auto child = children[node][(value >> bit) & 1u];
        if (child < 0) return;
        node = static_cast<std::size_t>(child);
        path[depth + 1] = node;
    }
    if (count[node] == 0) return;
    for (const auto position : path) --count[position];
}

std::uint32_t minimum_xor(
    const std::array<std::array<std::int32_t, 2>, max_nodes> &children,
    const std::array<std::int32_t, max_nodes> &count, std::uint32_t value) noexcept {
    std::size_t node = 0;
    std::uint32_t result = 0;
    for (int bit = static_cast<int>(max_bits) - 1; bit >= 0; --bit) {
        const auto preferred = (value >> bit) & 1u;
        const auto child = children[node][preferred];
        if (child >= 0 && count[static_cast<std::size_t>(child)] > 0) {
            node = static_cast<std::size_t>(child);
        } else {
            result |= 1u << bit;
            node = static_cast<std::size_t>(children[node][preferred ^ 1u]);
        }
    }
    return result;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t set_xor_min(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input_values) return -1;
    const auto q_value = input[0];
    if (q_value < 1 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto q = static_cast<std::size_t>(q_value);
    if (length != 1 + 2 * q) return -1;
    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto offset = 1 + 2 * operation;
        if (input[offset] < 0 || input[offset] > 2 || input[offset + 1] < 0 ||
            input[offset + 1] >= (std::int64_t{1} << max_bits)) return -1;
    }

    std::array<std::array<std::int32_t, 2>, max_nodes> children{};
    for (auto &child : children) child = {-1, -1};
    std::array<std::int32_t, max_nodes> count{};
    std::size_t node_count = 1;
    std::array<std::int64_t, max_q> answers{};
    std::size_t answer_count = 0;
    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto offset = 1 + 2 * operation;
        const auto kind = input[offset];
        const auto value = static_cast<std::uint32_t>(input[offset + 1]);
        if (kind == 0) {
            insert_value(children, count, node_count, value);
        } else if (kind == 1) {
            remove_value(children, count, value);
        } else {
            if (count[0] == 0) return -1;
            answers[answer_count++] = minimum_xor(children, count, value);
        }
    }

    const auto required = 8 * answer_count;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < answer_count; ++index)
        store_i64_le(output, 8 * index, answers[index]);
    return static_cast<std::int64_t>(required);
}
