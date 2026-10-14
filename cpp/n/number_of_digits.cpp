#include <cstdint>

extern "C" std::int64_t number_of_digits(std::int64_t value) noexcept
{
    std::uint64_t magnitude = value < 0 ? static_cast<std::uint64_t>(-(value + 1)) + 1U
                                         : static_cast<std::uint64_t>(value);
    std::int64_t digits = 1;
    while (magnitude >= 10U) { magnitude /= 10U; ++digits; }
    return digits;
}
