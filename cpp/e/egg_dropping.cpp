#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_eggs = 12;
constexpr std::size_t max_floors = 128;
constexpr std::size_t floor_width = max_floors + 1;
}

extern "C" std::int64_t egg_dropping(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 2) return std::numeric_limits<std::int64_t>::min();
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_eggs) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_floors)) {
        return std::numeric_limits<std::int64_t>::min();
    }

    const auto eggs = static_cast<std::size_t>(input[0]);
    const auto floors = static_cast<std::size_t>(input[1]);
    std::int64_t dp[(max_eggs + 1) * floor_width]{};

    for (std::size_t egg = 1; egg <= eggs; ++egg) dp[egg * floor_width + 1] = 1;
    for (std::size_t floor = 1; floor <= floors; ++floor) dp[floor_width + floor] = static_cast<std::int64_t>(floor);
    for (std::size_t egg = 2; egg <= eggs; ++egg) {
        for (std::size_t floor = 2; floor <= floors; ++floor) {
            auto best = std::numeric_limits<std::int64_t>::max();
            for (std::size_t drop = 1; drop <= floor; ++drop) {
                const auto breaks = dp[(egg - 1) * floor_width + drop - 1];
                const auto survives = dp[egg * floor_width + floor - drop];
                const auto worst = 1 + (breaks > survives ? breaks : survives);
                if (worst < best) best = worst;
            }
            dp[egg * floor_width + floor] = best;
        }
    }
    return dp[eggs * floor_width + floors];
}
