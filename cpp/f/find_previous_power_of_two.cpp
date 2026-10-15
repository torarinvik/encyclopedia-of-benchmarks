// Preserve the pinned source's repeated-doubling search on its i32 domain.
#include <cstdint>

extern "C" std::int64_t find_previous_power_of_two(std::int64_t number) noexcept
{
    if (number < 0 || number > INT32_MAX) return -1;
    if (number == 0) return 0;

    std::int64_t power = 1;
    while (power <= number) power <<= 1;
    return number > 1 ? power >> 1 : 1;
}
