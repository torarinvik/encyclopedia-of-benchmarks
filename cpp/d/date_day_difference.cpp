// Absolute difference between two validated Gregorian dates.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_ordinal = INT64_MIN;
constexpr std::size_t max_length = 21;

std::int64_t floor_div(std::int64_t value, std::int64_t divisor) {
    std::int64_t quotient = value / divisor;
    if (value % divisor != 0 && value < 0) --quotient;
    return quotient;
}

bool leap_year(std::int64_t year) {
    return year % 400 == 0 || (year % 100 != 0 && year % 4 == 0);
}

std::int64_t date_ordinal(std::int64_t day, std::int64_t month, std::int64_t year) {
    const std::int64_t correction = month <= 2 ? 0 : (leap_year(year) ? -1 : -2);
    const std::int64_t prior = year - 1;
    return 365 * prior + floor_div(prior, 4) - floor_div(prior, 100) + floor_div(prior, 400) +
           day + floor_div(367 * month - 362, 12) + correction;
}

std::int64_t parse_date(const std::int64_t *values, std::size_t start, std::size_t end) {
    std::size_t pos = start;
    std::int64_t day = 0, month = 0, year = 0;
    std::size_t digits = 0;
    while (pos < end && values[pos] >= '0' && values[pos] <= '9' && digits < 3) {
        day = day * 10 + values[pos++] - '0';
        ++digits;
    }
    if (digits < 1 || digits > 2 || pos >= end || values[pos++] != '/') return invalid_ordinal;
    digits = 0;
    while (pos < end && values[pos] >= '0' && values[pos] <= '9' && digits < 3) {
        month = month * 10 + values[pos++] - '0';
        ++digits;
    }
    if (digits < 1 || digits > 2 || pos >= end || values[pos++] != '/' || end - pos != 4)
        return invalid_ordinal;
    for (; pos < end; ++pos) {
        if (values[pos] < '0' || values[pos] > '9') return invalid_ordinal;
        year = year * 10 + values[pos] - '0';
    }
    if (month < 1 || month > 12 || day < 1) return invalid_ordinal;
    constexpr int month_lengths[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    std::int64_t max_day = month_lengths[month - 1];
    if (month == 2 && leap_year(year)) max_day = 29;
    if (day > max_day) return invalid_ordinal;
    return date_ordinal(day, month, year);
}
}

extern "C" std::int64_t date_day_difference(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 17 || length > max_length) return -1;
    std::size_t separator = length;
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] == '|') {
            if (separator != length) return -1;
            separator = i;
        }
    }
    if (separator == length) return -1;
    const std::int64_t first = parse_date(values, 0, separator);
    const std::int64_t second = parse_date(values, separator + 1, length);
    if (first == invalid_ordinal || second == invalid_ordinal) return -1;
    return first > second ? first - second : second - first;
}
