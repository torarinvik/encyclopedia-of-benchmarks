/* Absolute difference between two validated Gregorian dates. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1)
#define INVALID_ORDINAL INT64_MIN

static int64_t floor_div(int64_t value, int64_t divisor)
{
    int64_t quotient = value / divisor;
    int64_t remainder = value % divisor;
    if (remainder != 0 && value < 0) --quotient;
    return quotient;
}

static int leap_year(int64_t year)
{
    return year % 400 == 0 || (year % 100 != 0 && year % 4 == 0);
}

static int64_t date_ordinal(int64_t day, int64_t month, int64_t year)
{
    int64_t correction = month <= 2 ? 0 : (leap_year(year) ? -1 : -2);
    int64_t prior = year - 1;
    return 365 * prior + floor_div(prior, 4) - floor_div(prior, 100) + floor_div(prior, 400) +
           day + floor_div(367 * month - 362, 12) + correction;
}

static int64_t parse_date(const int64_t *values, size_t start, size_t end)
{
    size_t pos = start;
    int64_t day = 0, month = 0, year = 0;
    size_t digits = 0;
    while (pos < end && values[pos] >= '0' && values[pos] <= '9' && digits < 3) {
        day = day * 10 + values[pos] - '0';
        ++digits;
        ++pos;
    }
    if (digits < 1 || digits > 2 || pos >= end || values[pos++] != '/') return INVALID_ORDINAL;

    digits = 0;
    while (pos < end && values[pos] >= '0' && values[pos] <= '9' && digits < 3) {
        month = month * 10 + values[pos] - '0';
        ++digits;
        ++pos;
    }
    if (digits < 1 || digits > 2 || pos >= end || values[pos++] != '/' || end - pos != 4)
        return INVALID_ORDINAL;
    for (; pos < end; ++pos) {
        if (values[pos] < '0' || values[pos] > '9') return INVALID_ORDINAL;
        year = year * 10 + values[pos] - '0';
    }
    if (month < 1 || month > 12 || year < 0 || year > 9999 || day < 1) return INVALID_ORDINAL;
    static const int month_lengths[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    int64_t max_day = month_lengths[month - 1];
    if (month == 2 && leap_year(year)) max_day = 29;
    if (day > max_day) return INVALID_ORDINAL;
    return date_ordinal(day, month, year);
}

int64_t date_day_difference(const int64_t *values, size_t length)
{
    if (values == NULL || length < 17 || length > 21) return INVALID_RESULT;
    size_t separator = length;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] == '|') {
            if (separator != length) return INVALID_RESULT;
            separator = i;
        }
    }
    if (separator == length) return INVALID_RESULT;
    int64_t first = parse_date(values, 0, separator);
    int64_t second = parse_date(values, separator + 1, length);
    if (first == INVALID_ORDINAL || second == INVALID_ORDINAL) return INVALID_RESULT;
    return first > second ? first - second : second - first;
}
