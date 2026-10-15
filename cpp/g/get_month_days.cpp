#include <cstdint>

namespace {
bool is_leap_year(std::int64_t year)
{
    return year % 400 == 0 || (year % 100 != 0 && year % 4 == 0);
}
}

// Return the pinned JavaScript helper's month length.
extern "C" std::int64_t get_month_days(std::int64_t month_number, std::int64_t year) noexcept
{
    if (year < 0 || year > 9999) return -1;
    switch (month_number) {
        case 1: case 3: case 5: case 7: case 8: case 10: case 12: return 31;
        case 4: case 6: case 9: case 11: return 30;
        case 2: return is_leap_year(year) ? 29 : 28;
        default: return -1;
    }
}
