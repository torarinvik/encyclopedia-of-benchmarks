#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_EGGS = 8;
constexpr std::size_t MAX_FLOORS = 32;
}

extern "C" std::int64_t egg_dropping_puzzle(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length != 2) return -1;
    const std::int64_t eggs_value = input[0];
    const std::int64_t floors_value = input[1];
    if (eggs_value < 1 || eggs_value > static_cast<std::int64_t>(MAX_EGGS)
        || floors_value < 1 || floors_value > static_cast<std::int64_t>(MAX_FLOORS)) return -1;

    const std::size_t eggs = static_cast<std::size_t>(eggs_value);
    const std::size_t floors = static_cast<std::size_t>(floors_value);
    std::int64_t dp[MAX_EGGS + 1][MAX_FLOORS + 1] = {};
    for (std::size_t egg = 1; egg <= eggs; ++egg) dp[egg][1] = 1;
    for (std::size_t floor_count = 1; floor_count <= floors; ++floor_count) dp[1][floor_count] = static_cast<std::int64_t>(floor_count);

    for (std::size_t egg = 2; egg <= eggs; ++egg) {
        for (std::size_t floor_count = 2; floor_count <= floors; ++floor_count) {
            std::int64_t best = static_cast<std::int64_t>(MAX_FLOORS + 1);
            for (std::size_t drop_floor = 1; drop_floor <= floor_count; ++drop_floor) {
                const std::int64_t broken = dp[egg - 1][drop_floor - 1];
                const std::int64_t survives = dp[egg][floor_count - drop_floor];
                const std::int64_t worst = broken > survives ? broken : survives;
                const std::int64_t candidate = worst + 1;
                if (candidate < best) best = candidate;
            }
            dp[egg][floor_count] = best;
        }
    }
    return dp[eggs][floors];
}
