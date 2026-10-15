/* Gregorian weekday by the pinned Rust month-offset recurrence. */
#include <stddef.h>
#include <stdint.h>

static int is_leap_year(int64_t year) {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
}

static int64_t month_offset(int64_t month) {
    static const int64_t offsets[12] = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
    return offsets[month - 1];
}

int64_t weekday_by_month_offsets(const int64_t *values, size_t length) {
    if (values == NULL || length != 3) return -1;
    const int64_t year = values[0], month = values[1], day = values[2];
    if (year < 100 || year > 9999 || month < 1 || month > 12) return -1;
    const int leap = is_leap_year(year);
    const int64_t days_in_month = month == 2 ? (leap ? 29 : 28)
        : (month == 4 || month == 6 || month == 9 || month == 11 ? 30 : 31);
    if (day < 1 || day > days_in_month) return -1;

    const int64_t adjusted_year = year - (month < 3 ? 1 : 0);
    return (adjusted_year + adjusted_year / 4 - adjusted_year / 100
        + adjusted_year / 400 + month_offset(month) + day) % 7;
}
