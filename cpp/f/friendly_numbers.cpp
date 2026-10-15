// Preserve the pinned JavaScript FriendlyNumbers divisor-loop behavior.
#include <cstdint>

namespace {
double abundancy_index(std::uint64_t number)
{
    std::uint64_t sum = number;
    for (std::uint64_t divisor = 1; divisor * 2 < number; ++divisor)
        if (number % divisor == 0) sum += divisor;
    return static_cast<double>(sum) / static_cast<double>(number);
}
}

extern "C" std::int64_t friendly_numbers(std::uint64_t first, std::uint64_t second) noexcept
{
    if (first == 0 || second == 0 || first == second || first > 1000 || second > 1000) return -1;
    return abundancy_index(first) == abundancy_index(second) ? 1 : 0;
}
