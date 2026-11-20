#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 64;
constexpr std::size_t kMaxInputLength = 1 + 2 * (kMaxN - 1);

void store_i64_le(std::uint8_t* output, std::size_t offset,
                  std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tree_center_rerooting_dp(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 1 + 2 * (n - 1)) return -1;

    std::array<std::array<std::size_t, kMaxN>, kMaxN> adjacency{};
    std::array<std::size_t, kMaxN> degree{};
    for (std::size_t edge = 0; edge + 1 < n; ++edge) {
        const auto offset = 1 + 2 * edge;
        const auto left_value = input[offset], right_value = input[offset + 1];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        const auto left = static_cast<std::size_t>(left_value);
        const auto right = static_cast<std::size_t>(right_value);
        adjacency[left][degree[left]++] = right;
        adjacency[right][degree[right]++] = left;
    }

    std::array<std::size_t, kMaxN> parent{}, order{};
    parent.fill(kMaxN);
    parent[0] = kMaxN + 1;
    order[0] = 0;
    std::size_t order_count = 1;
    for (std::size_t position = 0; position < order_count; ++position) {
        const auto vertex = order[position];
        for (std::size_t edge = 0; edge < degree[vertex]; ++edge) {
            const auto child = adjacency[vertex][edge];
            if (child == parent[vertex]) continue;
            if (parent[child] != kMaxN) return -1;
            parent[child] = vertex;
            order[order_count++] = child;
        }
    }
    if (order_count != n) return -1;

    std::array<std::size_t, kMaxN> down{}, best{}, second{}, best_child{};
    best_child.fill(kMaxN);
    for (std::size_t position = n; position > 0; --position) {
        const auto vertex = order[position - 1];
        for (std::size_t edge = 0; edge < degree[vertex]; ++edge) {
            const auto child = adjacency[vertex][edge];
            if (parent[child] != vertex) continue;
            const auto branch = down[child] + 1;
            if (branch > best[vertex]) {
                second[vertex] = best[vertex];
                best[vertex] = branch;
                best_child[vertex] = child;
            } else if (branch > second[vertex]) {
                second[vertex] = branch;
            }
        }
        down[vertex] = best[vertex];
    }

    std::array<std::ptrdiff_t, kMaxN> outside{};
    outside.fill(-1);
    for (std::size_t position = 0; position < n; ++position) {
        const auto vertex = order[position];
        for (std::size_t edge = 0; edge < degree[vertex]; ++edge) {
            const auto child = adjacency[vertex][edge];
            if (parent[child] != vertex) continue;
            const auto sibling = best_child[vertex] == child ? second[vertex] : best[vertex];
            outside[child] = static_cast<std::ptrdiff_t>(
                (outside[vertex] > static_cast<std::ptrdiff_t>(sibling)
                    ? outside[vertex] : static_cast<std::ptrdiff_t>(sibling)) + 1);
        }
    }

    std::size_t radius = kMaxN;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        const auto outside_height = outside[vertex] < 0 ? 0U : static_cast<std::size_t>(outside[vertex]);
        const auto eccentricity = std::max(down[vertex], outside_height);
        if (eccentricity < radius) radius = eccentricity;
    }
    std::array<std::int64_t, 2> centers{};
    std::size_t center_count = 0;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        const auto outside_height = outside[vertex] < 0 ? 0U : static_cast<std::size_t>(outside[vertex]);
        if (std::max(down[vertex], outside_height) == radius)
            centers[center_count++] = static_cast<std::int64_t>(vertex);
    }
    const auto required = 8 * center_count;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < center_count; ++index)
        store_i64_le(output, 8 * index, centers[index]);
    return static_cast<std::int64_t>(required);
}
