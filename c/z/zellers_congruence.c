/* Return the Gregorian weekday for [year, month, day]; Sunday is zero. */
#include <stddef.h>
#include <stdint.h>

static int is_leap_year(int64_t year)
{
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
}

int64_t zellers_congruence(const int64_t *date, size_t length)
{
    if (date == NULL || length != 3) return -1;
    int64_t year = date[0], month = date[1], day = date[2];
    if (year < 46 || year > 8499 || month < 1 || month > 12 || day < 1) return -1;
    static const int days_by_month[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    int64_t maximum_day = days_by_month[month - 1] + (month == 2 && is_leap_year(year));
    if (day > maximum_day) return -1;

    if (month <= 2) { --year; month += 12; }
    const int64_t century = year / 100;
    const int64_t year_of_century = year % 100;
    const int64_t month_term = (260 * month - 539) / 100;
    const int64_t total = day + year_of_century + month_term + century / 4 +
                          year_of_century / 4 - 2 * century;
    int64_t weekday = total % 7;
    if (weekday < 0) weekday += 7;
    return weekday;
}
