#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_states = 3;
constexpr std::size_t first_subsets = 1u << max_states;
constexpr std::size_t second_subsets = 1u << first_subsets;
}

extern "C" std::int64_t brzozowski_dfa_minimization(const std::int64_t *input,
                                                      std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 10) return -1;
    const auto n64 = input[0];
    const auto start64 = input[1];
    const auto accepting64 = input[2];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(max_states)
        || start64 < 0 || start64 >= n64 || accepting64 < 0
        || accepting64 >= (std::int64_t{1} << n64)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    if (length != 3 + 2 * n) return -1;
    const auto start = static_cast<std::size_t>(start64);
    const auto accepting = static_cast<unsigned int>(accepting64);
    std::array<std::array<std::size_t, 2>, max_states> transitions{};
    for (std::size_t state = 0; state < n; ++state) {
        for (std::size_t symbol = 0; symbol < 2; ++symbol) {
            const auto target = input[3 + 2 * state + symbol];
            if (target < 0 || target >= n64) return -1;
            transitions[state][symbol] = static_cast<std::size_t>(target);
        }
    }

    std::array<unsigned int, first_subsets> first_masks{};
    std::array<std::array<std::size_t, 2>, first_subsets> first_delta{};
    std::array<bool, first_subsets> first_final{};
    std::array<int, first_subsets> first_id;
    first_id.fill(-1);
    std::size_t first_count = 1;
    first_masks[0] = accepting;
    first_id[accepting] = 0;
    for (std::size_t cursor = 0; cursor < first_count; ++cursor) {
        const auto subset = first_masks[cursor];
        first_final[cursor] = ((subset >> start) & 1u) != 0;
        for (std::size_t symbol = 0; symbol < 2; ++symbol) {
            unsigned int predecessor = 0;
            for (std::size_t state = 0; state < n; ++state)
                if ((subset & (1u << transitions[state][symbol])) != 0)
                    predecessor |= 1u << state;
            if (first_id[predecessor] < 0) {
                first_id[predecessor] = static_cast<int>(first_count);
                first_masks[first_count++] = predecessor;
            }
            first_delta[cursor][symbol] = static_cast<std::size_t>(first_id[predecessor]);
        }
    }
    unsigned int first_accepting = 0;
    for (std::size_t state = 0; state < first_count; ++state)
        if (first_final[state]) first_accepting |= 1u << state;

    std::array<unsigned int, second_subsets> queue{};
    std::array<bool, second_subsets> seen{};
    std::size_t count = 1;
    queue[0] = first_accepting;
    seen[first_accepting] = true;
    for (std::size_t cursor = 0; cursor < count; ++cursor) {
        const auto subset = queue[cursor];
        for (std::size_t symbol = 0; symbol < 2; ++symbol) {
            unsigned int predecessor = 0;
            for (std::size_t state = 0; state < first_count; ++state)
                if ((subset & (1u << first_delta[state][symbol])) != 0)
                    predecessor |= 1u << state;
            if (!seen[predecessor]) {
                seen[predecessor] = true;
                queue[count++] = predecessor;
            }
        }
    }
    return static_cast<std::int64_t>(count);
}
