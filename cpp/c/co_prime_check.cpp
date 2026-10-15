// Return whether two nonnegative int32 values have greatest common divisor one.
#include <cstdint>
#include <limits>

extern "C" std::int64_t co_prime_check(std::uint64_t first, std::uint64_t second) noexcept
{
    if (first > static_cast<std::uint64_t>(std::numeric_limits<std::int32_t>::max()) ||
        second > static_cast<std::uint64_t>(std::numeric_limits<std::int32_t>::max())) return -1;
    while (second != 0) {
        const auto remainder = first % second;
        first = second;
        second = remainder;
    }
    return first == 1 ? 1 : 0;
}
