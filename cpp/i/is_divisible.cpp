// Remainder check from the pinned JavaScript and TypeScript sources.
#include <cstdint>

extern "C" std::int64_t is_divisible(std::uint64_t dividend, std::uint64_t divisor) noexcept
{
    if (dividend > 1'000'000'000 || divisor == 0 || divisor > 1'000'000'000) return -1;
    return dividend % divisor == 0 ? 1 : 0;
}
