#include <cstdint>

namespace {
bool is_leap_year(int year)
{
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
}
}

extern "C" std::int64_t problem19(std::int64_t ignored) noexcept
{
    if (ignored != 0) return -1;
    int weekday = 2; // 1 January 1901 was Tuesday; Sunday is 0.
    std::int64_t count = 0;
    for (int year = 1901; year <= 2000; ++year) {
        for (int month = 1; month <= 12; ++month) {
            if (weekday == 0) ++count;
            int days = 31;
            if (month == 4 || month == 6 || month == 9 || month == 11) days = 30;
            if (month == 2) days = is_leap_year(year) ? 29 : 28;
            weekday = (weekday + days) % 7;
        }
    }
    return count;
}
