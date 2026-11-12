#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input = max_n + 2;
constexpr std::int64_t max_weight = 1'000'000;
constexpr std::int64_t infinity = std::int64_t{1} << 62;

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t garsia_wachs_alphabetic_tree(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (!input || length < 2 || length > max_input) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != n + 1) return -1;

    std::array<std::int64_t, 2 * max_n - 1> node_weight{};
    std::array<int, 2 * max_n - 1> left{}, right{};
    std::array<int, max_n> active{};
    left.fill(-1);
    right.fill(-1);
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 0 || input[i + 1] > max_weight) return -1;
        node_weight[i] = input[i + 1];
        active[i] = static_cast<int>(i);
    }

    std::size_t active_count = n, next_node = n;
    while (active_count > 1) {
        std::size_t pair = 0;
        for (; pair + 1 < active_count; ++pair) {
            const auto following = pair + 2 < active_count
                ? node_weight[static_cast<std::size_t>(active[pair + 2])] : infinity;
            if (node_weight[static_cast<std::size_t>(active[pair])] <= following) break;
        }
        const int first = active[pair], second = active[pair + 1];
        const auto combined = node_weight[static_cast<std::size_t>(first)] + node_weight[static_cast<std::size_t>(second)];
        node_weight[next_node] = combined;
        left[next_node] = first;
        right[next_node] = second;
        std::size_t earlier = pair;
        while (earlier > 0 && node_weight[static_cast<std::size_t>(active[earlier - 1])] < combined) --earlier;
        const std::size_t insert_at = earlier;
        for (std::size_t i = pair; i + 2 < active_count; ++i) active[i] = active[i + 2];
        active_count -= 2;
        for (std::size_t i = active_count; i > insert_at; --i) active[i] = active[i - 1];
        active[insert_at] = static_cast<int>(next_node);
        ++active_count;
        ++next_node;
    }

    std::array<int, max_n> depths{};
    std::array<int, 2 * max_n> stack_node{}, stack_depth{};
    std::size_t top = 1;
    stack_node[0] = active[0];
    while (top > 0) {
        --top;
        const int node = stack_node[top], depth = stack_depth[top];
        if (static_cast<std::size_t>(node) < n) depths[static_cast<std::size_t>(node)] = depth;
        else {
            stack_node[top] = right[static_cast<std::size_t>(node)]; stack_depth[top++] = depth + 1;
            stack_node[top] = left[static_cast<std::size_t>(node)]; stack_depth[top++] = depth + 1;
        }
    }

    std::array<int, 2 * max_n - 1> ordered_left{}, ordered_right{};
    ordered_left.fill(-1);
    ordered_right.fill(-1);
    std::array<int, 2 * max_n> code_node{}, code_depth{};
    std::size_t code_top = 0, next_ordered = n;
    for (std::size_t leaf = 0; leaf < n; ++leaf) {
        code_node[code_top] = static_cast<int>(leaf);
        code_depth[code_top++] = depths[leaf];
        while (code_top >= 2 && code_depth[code_top - 1] == code_depth[code_top - 2]) {
            const int level = code_depth[code_top - 1];
            if (level <= 0 || next_ordered >= 2 * n - 1) return -1;
            ordered_left[next_ordered] = code_node[code_top - 2];
            ordered_right[next_ordered] = code_node[code_top - 1];
            code_top -= 2;
            code_node[code_top] = static_cast<int>(next_ordered);
            code_depth[code_top++] = level - 1;
            ++next_ordered;
        }
    }
    if (code_top != 1 || code_depth[0] != 0 || next_ordered != 2 * n - 1) return -1;
    std::int64_t cost = 0;
    for (std::size_t i = 0; i < n; ++i) cost += input[i + 1] * depths[i];
    const std::size_t output_bytes = 8 * (n + 1);
    if (!output || capacity < output_bytes) return -2;
    put_i64_le(output, 0, cost);
    for (std::size_t i = 0; i < n; ++i) put_i64_le(output, 8 * (i + 1), depths[i]);
    return static_cast<std::int64_t>(output_bytes);
}
