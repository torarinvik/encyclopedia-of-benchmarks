/* Totient-table maximum ratio search for Project Euler 69. */
#include <cstdint>
#include <vector>

namespace {
constexpr std::int64_t MAX_LIMIT = 1000000;
}

extern "C" std::int64_t problem69(std::int64_t inclusive_limit) noexcept
{
    if (inclusive_limit < 1 || inclusive_limit > MAX_LIMIT) return -1;
    const std::size_t limit = static_cast<std::size_t>(inclusive_limit);
    std::vector<std::uint32_t> phi(limit + 1);
    for (std::size_t value = 0; value <= limit; ++value) phi[value] = static_cast<std::uint32_t>(value);
    for (std::size_t number = 2; number <= limit; ++number) {
        if (phi[number] != number) continue;
        --phi[number];
        for (std::size_t multiple = number * 2; multiple <= limit; multiple += number) {
            phi[multiple] = (phi[multiple] / static_cast<std::uint32_t>(number))
                          * static_cast<std::uint32_t>(number - 1);
        }
    }
    std::size_t answer = 1;
    for (std::size_t number = 1; number <= limit; ++number) {
        if (static_cast<std::uint64_t>(number) * phi[answer]
            > static_cast<std::uint64_t>(answer) * phi[number]) answer = number;
    }
    return static_cast<std::int64_t>(answer);
}
