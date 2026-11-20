#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t INF = INT64_C(1) << 60;
constexpr std::size_t MAX_STATES = 256;
}

extern "C" std::int64_t minimum_cost_bipartite_edge_cover_subset_dp(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > 67) return -1;
    const std::int64_t left_value = input[0];
    const std::int64_t right_value = input[1];
    if (left_value < 1 || left_value > 8 || right_value < 1 || right_value > 8) return -1;
    const std::size_t left_count = static_cast<std::size_t>(left_value);
    const std::size_t right_count = static_cast<std::size_t>(right_value);
    if (length != 2 + left_count * right_count) return -1;
    for (std::size_t edge = 0; edge < left_count * right_count; ++edge)
        if (input[2 + edge] < 0 || input[2 + edge] > 1000) return -1;

    const std::size_t states = std::size_t{1} << right_count;
    std::array<std::int64_t, MAX_STATES> current;
    std::array<std::int64_t, MAX_STATES> following;
    std::array<std::int64_t, MAX_STATES> subset_cost;
    current.fill(INF);
    current[0] = 0;
    for (std::size_t left = 0; left < left_count; ++left) {
        subset_cost[0] = 0;
        for (std::size_t subset = 1; subset < states; ++subset) {
            const std::size_t bit = subset & (~subset + 1);
            std::size_t right = 0;
            while (((bit >> right) & 1) == 0) ++right;
            subset_cost[subset] = subset_cost[subset ^ bit] + input[2 + left * right_count + right];
        }
        following.fill(INF);
        for (std::size_t covered = 0; covered < states; ++covered) {
            if (current[covered] == INF) continue;
            for (std::size_t selected = 1; selected < states; ++selected) {
                const std::size_t combined = covered | selected;
                const std::int64_t candidate = current[covered] + subset_cost[selected];
                if (candidate < following[combined]) following[combined] = candidate;
            }
        }
        current = following;
    }
    return current[states - 1];
}
