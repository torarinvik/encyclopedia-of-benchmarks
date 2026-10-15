// Kuhn DFS augmenting-path maximum matching for a bounded bipartite graph.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_side = 64;
constexpr std::size_t max_edges = max_side * max_side;
using Adjacency = std::array<bool, max_side * max_side>;

bool try_augment(std::size_t left, std::size_t right_count, const Adjacency &adjacency,
                 std::array<bool, max_side> &seen_right,
                 std::array<int, max_side> &pair_right) {
    for (std::size_t right = 0; right < right_count; ++right) {
        if (!adjacency[left * max_side + right] || seen_right[right]) continue;
        seen_right[right] = true;
        const int mate = pair_right[right];
        if (mate < 0 || try_augment(static_cast<std::size_t>(mate), right_count,
                                    adjacency, seen_right, pair_right)) {
            pair_right[right] = static_cast<int>(left);
            return true;
        }
    }
    return false;
}
}

extern "C" std::int64_t bipartite_matching_kuhn(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 64 ||
        input[2] < 0 || input[2] > static_cast<std::int64_t>(max_edges)) return -1;
    const auto left_count = static_cast<std::size_t>(input[0]);
    const auto right_count = static_cast<std::size_t>(input[1]);
    const auto edge_count = static_cast<std::size_t>(input[2]);
    if (length != 3 + 2 * edge_count) return -1;
    Adjacency adjacency{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left = input[3 + 2 * edge], right = input[4 + 2 * edge];
        if (left < 0 || left >= static_cast<std::int64_t>(left_count) ||
            right < 0 || right >= static_cast<std::int64_t>(right_count)) return -1;
        adjacency[static_cast<std::size_t>(left) * max_side + static_cast<std::size_t>(right)] = true;
    }
    std::array<int, max_side> pair_right;
    pair_right.fill(-1);
    std::int64_t matching = 0;
    for (std::size_t left = 0; left < left_count; ++left) {
        std::array<bool, max_side> seen_right{};
        if (try_augment(left, right_count, adjacency, seen_right, pair_right)) ++matching;
    }
    return matching;
}
