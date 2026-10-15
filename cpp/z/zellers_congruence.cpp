// Return the Gregorian weekday for [year, month, day]; Sunday is zero.
#include <cstddef>
#include <cstdint>

static bool is_leap_year(std::int64_t year) noexcept
{
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
}

extern "C" std::int64_t zellers_congruence(const std::int64_t *date,
                                            std::size_t length) noexcept
{
    if (date == nullptr || length != 3) return -1;
    auto year = date[0];
    auto month = date[1];
    const auto day = date[2];
    if (year < 46 || year > 8499 || month < 1 || month > 12 || day < 1) return -1;
    constexpr int days_by_month[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    const auto maximum_day = days_by_month[month - 1] + (month == 2 && is_leap_year(year));
    if (day > maximum_day) return -1;

    if (month <= 2) { --year; month += 12; }
    const auto century = year / 100;
    const auto year_of_century = year % 100;
    const auto month_term = (260 * month - 539) / 100;
    const auto total = day + year_of_century + month_term + century / 4 +
                       year_of_century / 4 - 2 * century;
    auto weekday = total % 7;
    if (weekday < 0) weekday += 7;
    return weekday;
}
