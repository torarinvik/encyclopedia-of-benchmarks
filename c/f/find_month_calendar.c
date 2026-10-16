#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MIN_YEAR 1899
#define MAX_YEAR 2100
#define MAX_OUTPUT_BYTES 181

static int is_leap_year(int64_t year) {
    return year % 400 == 0 || (year % 100 != 0 && year % 4 == 0);
}

static int month_length(int64_t year, int64_t month) {
    static const int common_days[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if (month == 2 && is_leap_year(year)) return 29;
    return common_days[month - 1];
}

static size_t start_offset(int64_t month, int64_t year) {
    int64_t difference = 0;
    if (year >= 1900) {
        for (int64_t y = 1900; y < year; ++y)
            difference += is_leap_year(y) ? 366 : 365;
        for (int64_t m = 1; m < month; ++m) difference += month_length(year, m);
        return (size_t)(difference % 7);
    }
    for (int64_t y = year; y < 1900; ++y)
        difference += is_leap_year(y) ? 366 : 365;
    for (int64_t m = 1; m < month; ++m) difference -= month_length(1900, m);
    return (size_t)((7 - difference % 7) % 7);
}

static size_t write_cell(uint8_t *output, size_t position, int day) {
    if (day == 0) {
        for (int i = 0; i < 4; ++i) output[position++] = ' ';
    } else if (day >= 10) {
        output[position++] = (uint8_t)('0' + day / 10);
        output[position++] = (uint8_t)('0' + day % 10);
        output[position++] = ' ';
        output[position++] = ' ';
    } else {
        output[position++] = (uint8_t)('0' + day);
        output[position++] = ' ';
        output[position++] = ' ';
        output[position++] = ' ';
    }
    return position;
}

int64_t find_month_calendar(const int64_t *values, size_t length,
                            uint8_t *output, size_t output_capacity) {
    if (values == NULL || length != 2) return -1;
    const int64_t month = values[0], year = values[1];
    if (month < 1 || month > 12 || year < MIN_YEAR || year > MAX_YEAR) return -1;

    const size_t offset = start_offset(month, year);
    const size_t total_cells = offset + (size_t)month_length(year, month);
    const size_t required = 27 + total_cells * 4 + (total_cells + 6) / 7;
    if (required > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || output_capacity < required) return -2;

    static const uint8_t header[] = "M   T   W   Th  F   S   Su\n";
    memcpy(output, header, sizeof(header) - 1);
    size_t written = sizeof(header) - 1;
    size_t cursor = 0;
    while (cursor < total_cells) {
        size_t cells = total_cells - cursor;
        if (cells > 7) cells = 7;
        for (size_t column = 0; column < cells; ++column) {
            const size_t cell = cursor + column;
            const int day = cell < offset ? 0 : (int)(cell - offset + 1);
            written = write_cell(output, written, day);
        }
        output[written++] = '\n';
        cursor += cells;
    }
    return (int64_t)written;
}
