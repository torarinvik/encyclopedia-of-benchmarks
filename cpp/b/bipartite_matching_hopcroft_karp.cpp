// Hopcroft-Karp maximum cardinality matching for a bounded bipartite graph.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_side = 64;
constexpr std::size_t max_edges = max_side * max_side;
constexpr int inf_distance = 1'000'000;
using Adjacency = std::array<bool, max_side * max_side>;

bool dfs_augment(std::size_t left, std::size_t right_count, const Adjacency &adjacency,
                 std::array<int, max_side> &distance, int nil_distance,
                 std::array<int, max_side> &pair_left,
                 std::array<int, max_side> &pair_right) {
    for (std::size_t right = 0; right < right_count; ++right) {
        if (!adjacency[left * max_side + right]) continue;
        const int mate = pair_right[right];
        if (mate < 0) {
            if (distance[left] + 1 != nil_distance) continue;
            pair_left[left] = static_cast<int>(right);
            pair_right[right] = static_cast<int>(left);
            return true;
        }
        if (distance[static_cast<std::size_t>(mate)] == distance[left] + 1 &&
            dfs_augment(static_cast<std::size_t>(mate), right_count, adjacency, distance,
                        nil_distance, pair_left, pair_right)) {
            pair_left[left] = static_cast<int>(right);
            pair_right[right] = static_cast<int>(left);
            return true;
        }
    }
    distance[left] = inf_distance;
    return false;
}

int bfs_layers(std::size_t left_count, std::size_t right_count, const Adjacency &adjacency,
               const std::array<int, max_side> &pair_right,
               std::array<int, max_side> &distance) {
    std::array<std::size_t, max_side> queue{};
    std::size_t head = 0, tail = 0;
    for (std::size_t left = 0; left < left_count; ++left) {
        if (distance[left] == 0) queue[tail++] = left;
    }
    int nil_distance = inf_distance;
    while (head < tail) {
        const auto left = queue[head++];
        if (distance[left] + 1 > nil_distance) continue;
        for (std::size_t right = 0; right < right_count; ++right) {
            if (!adjacency[left * max_side + right]) continue;
            const int mate = pair_right[right];
            if (mate < 0) {
                if (distance[left] + 1 < nil_distance) nil_distance = distance[left] + 1;
            } else if (distance[static_cast<std::size_t>(mate)] < 0) {
                distance[static_cast<std::size_t>(mate)] = distance[left] + 1;
                queue[tail++] = static_cast<std::size_t>(mate);
            }
        }
    }
    return nil_distance;
}
}

extern "C" std::int64_t bipartite_matching_hopcroft_karp(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || input[0] < 0 || input[0] > 64 ||
        input[1] < 0 || input[1] > 64 || input[2] < 0 || input[2] > static_cast<std::int64_t>(max_edges)) return -1;
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
    std::array<int, max_side> pair_left, pair_right, distance;
    pair_left.fill(-1);
    pair_right.fill(-1);
    std::int64_t matching = 0;
    for (;;) {
        for (std::size_t left = 0; left < left_count; ++left)
            distance[left] = pair_left[left] < 0 ? 0 : -1;
        const int nil_distance = bfs_layers(left_count, right_count, adjacency, pair_right, distance);
        if (nil_distance == inf_distance) break;
        for (std::size_t left = 0; left < left_count; ++left)
            if (pair_left[left] < 0 && dfs_augment(left, right_count, adjacency, distance,
                                                   nil_distance, pair_left, pair_right)) ++matching;
    }
    return matching;
}
