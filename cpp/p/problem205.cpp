/* Return the Peter-over-Colin win probability in units of 1e-7. */
#include <array>
#include <cstdint>

namespace {
constexpr std::int64_t max_total = 36;
constexpr std::int64_t scale = 10'000'000;
void distribution(std::int64_t sides, std::int64_t dice, std::array<std::int64_t, 37>& output)
{
    std::array<std::int64_t, 37> current{}, next{};
    current[0] = 1;
    for (std::int64_t die = 0; die < dice; ++die) {
        next.fill(0);
        for (std::int64_t total = 0; total <= max_total; ++total) if (current[std::size_t(total)] != 0)
            for (std::int64_t face = 1; face <= sides; ++face) next[std::size_t(total + face)] += current[std::size_t(total)];
        current = next;
    }
    output = current;
}
}

extern "C" std::int64_t problem205(std::int64_t placeholder) noexcept
{
    if (placeholder != 0) return -1;
    std::array<std::int64_t, 37> peter{}, colin{};
    distribution(4, 9, peter); distribution(6, 6, colin);
    std::int64_t wins = 0, colin_below = 0;
    for (std::int64_t total = 0; total <= max_total; ++total) {
        if (total >= 9) wins += peter[std::size_t(total)] * colin_below;
        colin_below += colin[std::size_t(total)];
    }
    constexpr std::int64_t games = INT64_C(262144) * INT64_C(46656);
    const auto scaled = wins * scale;
    auto rounded = scaled / games;
    const auto remainder = scaled % games;
    if (2 * remainder > games || (2 * remainder == games && rounded % 2 != 0)) ++rounded;
    return rounded;
}
