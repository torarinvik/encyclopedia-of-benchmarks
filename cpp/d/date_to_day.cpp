/* Return the English weekday name for an ASCII d/m/yyyy date. */
#include <cstddef>
#include <cstdint>
#include <cstring>

static bool date_to_day_digit(int64_t value) { return value >= 48 && value <= 57; }
static bool date_to_day_parse_field(const int64_t *input, size_t date_length,
                                    size_t &cursor, size_t min_digits, size_t max_digits, int &result) {
    size_t start = cursor;
    int value = 0;
    while (cursor < date_length && date_to_day_digit(input[cursor])) {
        value = value * 10 + static_cast<int>(input[cursor] - 48);
        ++cursor;
    }
    size_t digits = cursor - start;
    if (digits < min_digits || digits > max_digits) return false;
    result = value;
    return true;
}
static bool date_to_day_leap(int year) {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
}

extern "C" int64_t date_to_day(const int64_t *input, size_t length, uint8_t *output,
                                size_t output_capacity) {
    if (input == nullptr || length < 9 || length > 11 || input[length - 1] != 0) return -1;
    const size_t date_length = length - 1;
    size_t cursor = 0;
    int day, month, year;
    if (!date_to_day_parse_field(input, date_length, cursor, 1, 2, day) ||
        cursor >= date_length || input[cursor++] != 47 ||
        !date_to_day_parse_field(input, date_length, cursor, 1, 2, month) ||
        cursor >= date_length || input[cursor++] != 47 ||
        !date_to_day_parse_field(input, date_length, cursor, 4, 4, year) ||
        cursor != date_length) return -1;
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) return -1;
    static constexpr int month_days[12] = {31,28,31,30,31,30,31,31,30,31,30,31};
    int maximum_day = month_days[month - 1] + (month == 2 && date_to_day_leap(year));
    if (day > maximum_day) return -1;

    int adjusted_year = year;
    int adjusted_month = month;
    if (adjusted_month < 3) { --adjusted_year; adjusted_month += 12; }
    int year_of_century = adjusted_year % 100;
    int century = adjusted_year / 100;
    int weekday = (day + ((adjusted_month + 1) * 26) / 10 + year_of_century +
                   year_of_century / 4 + century / 4 + 5 * century) % 7;
    static constexpr const char *names[7] = {
        "Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"
    };
    size_t output_length = std::strlen(names[weekday]);
    if (output_capacity < output_length || output == nullptr) return -2;
    std::memcpy(output, names[weekday], output_length);
    return static_cast<int64_t>(output_length);
}
