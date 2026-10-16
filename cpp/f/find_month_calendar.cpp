#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::int64_t min_year = 1899;
constexpr std::int64_t max_year = 2100;
constexpr std::size_t max_output_bytes = 181;

bool is_leap_year(std::int64_t year) {
    return year % 400 == 0 || (year % 100 != 0 && year % 4 == 0);
}

int month_length(std::int64_t year, std::int64_t month) {
    constexpr int common_days[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if (month == 2 && is_leap_year(year)) return 29;
    return common_days[month - 1];
}

std::size_t start_offset(std::int64_t month, std::int64_t year) {
    std::int64_t difference = 0;
    if (year >= 1900) {
        for (std::int64_t y = 1900; y < year; ++y)
            difference += is_leap_year(y) ? 366 : 365;
        for (std::int64_t m = 1; m < month; ++m) difference += month_length(year, m);
        return static_cast<std::size_t>(difference % 7);
    }
    for (std::int64_t y = year; y < 1900; ++y)
        difference += is_leap_year(y) ? 366 : 365;
    for (std::int64_t m = 1; m < month; ++m) difference -= month_length(1900, m);
    return static_cast<std::size_t>((7 - difference % 7) % 7);
}

std::size_t write_cell(std::uint8_t *output, std::size_t position, int day) {
    if (day == 0) {
        for (int i = 0; i < 4; ++i) output[position++] = ' ';
    } else if (day >= 10) {
        output[position++] = static_cast<std::uint8_t>('0' + day / 10);
        output[position++] = static_cast<std::uint8_t>('0' + day % 10);
        output[position++] = ' ';
        output[position++] = ' ';
    } else {
        output[position++] = static_cast<std::uint8_t>('0' + day);
        output[position++] = ' ';
        output[position++] = ' ';
        output[position++] = ' ';
    }
    return position;
}
}

extern "C" std::int64_t find_month_calendar(const std::int64_t *values, std::size_t length,
                                             std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length != 2) return -1;
    const std::int64_t month = values[0], year = values[1];
    if (month < 1 || month > 12 || year < min_year || year > max_year) return -1;

    const std::size_t offset = start_offset(month, year);
    const std::size_t total_cells = offset + static_cast<std::size_t>(month_length(year, month));
    const std::size_t required = 27 + total_cells * 4 + (total_cells + 6) / 7;
    if (required > max_output_bytes) return -1;
    if (output == nullptr || output_capacity < required) return -2;

    static constexpr std::uint8_t header[] = "M   T   W   Th  F   S   Su\n";
    std::memcpy(output, header, sizeof(header) - 1);
    std::size_t written = sizeof(header) - 1;
    for (std::size_t cursor = 0; cursor < total_cells;) {
        const std::size_t cells = (total_cells - cursor < 7) ? total_cells - cursor : 7;
        for (std::size_t column = 0; column < cells; ++column) {
            const std::size_t cell = cursor + column;
            const int day = cell < offset ? 0 : static_cast<int>(cell - offset + 1);
            written = write_cell(output, written, day);
        }
        output[written++] = '\n';
        cursor += cells;
    }
    return static_cast<std::int64_t>(written);
}
