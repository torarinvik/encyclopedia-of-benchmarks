/* Return 1 for a positive Gregorian leap year, 0 otherwise, or -1 for invalid years. */
#include <cstdint>

extern "C" std::int64_t leap_year(std::int64_t year) noexcept
{
    if (year <= 0) return -1;
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0) ? 1 : 0;
}
