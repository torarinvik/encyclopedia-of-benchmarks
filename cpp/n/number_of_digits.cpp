#include <cstdint>

extern "C" std::int64_t number_of_digits(std::int64_t value) noexcept
{
    std::uint64_t magnitude = value < 0 ? static_cast<std::uint64_t>(-(value + 1)) + 1U
                                         : static_cast<std::uint64_t>(value);
    if (magnitude < 10) return 1;
    std::int64_t digits = 1;
    while (magnitude >= 10000U) {
        magnitude /= 10000U;
        digits += 4;
    }
    if (magnitude < 10) return digits;
    if (magnitude < 100) return digits + 1;
    return digits + (magnitude < 1000 ? 2 : 3);
}
