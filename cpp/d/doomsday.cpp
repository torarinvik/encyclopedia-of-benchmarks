// Gregorian weekday from Conway's Doomsday rule.
#include <cstddef>
#include <cstdint>

static bool is_leap_year(std::int64_t year) {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
}

static std::int64_t month_anchor(std::int64_t month, bool leap) {
    switch (month) {
        case 1: return leap ? 4 : 3;
        case 2: return leap ? 1 : 7;
        case 3: return 7;
        case 4: return 4;
        case 5: return 2;
        case 6: return 6;
        case 7: return 4;
        case 8: return 1;
        case 9: return 5;
        case 10: return 3;
        case 11: return 7;
        case 12: return 5;
        default: return -1;
    }
}

extern "C" std::int64_t doomsday(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length != 3) return -1;
    const std::int64_t year = values[0], month = values[1], day = values[2];
    if (year < 100 || year > 9999 || month < 1 || month > 12) return -1;
    const bool leap = is_leap_year(year);
    const std::int64_t days_in_month = month == 2 ? (leap ? 29 : 28)
        : (month == 4 || month == 6 || month == 9 || month == 11 ? 30 : 31);
    if (day < 1 || day > days_in_month) return -1;

    const std::int64_t within_century = year % 100;
    const std::int64_t century_anchor = (5 * ((year / 100) % 4) + 2) % 7;
    const std::int64_t doom = (within_century / 12 + within_century % 12
        + (within_century % 12) / 4 + century_anchor) % 7;
    std::int64_t weekday = (doom + day - month_anchor(month, leap)) % 7;
    if (weekday < 0) weekday += 7;
    return weekday;
}
