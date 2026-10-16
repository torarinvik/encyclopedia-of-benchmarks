module find_month_calendar;

const long MIN_YEAR = 1899;
const long MAX_YEAR = 2100;
const usz MAX_OUTPUT_BYTES = 181;

fn bool is_leap_year(long year) {
    return year % 400 == 0 || (year % 100 != 0 && year % 4 == 0);
}

fn long month_length(long year, long month) {
    long[12] common_days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if (month == 2 && is_leap_year(year)) return 29;
    return common_days[month - 1];
}

fn usz start_offset(long month, long year) {
    long difference = 0;
    if (year >= 1900) {
        for (long y = 1900; y < year; y++) {
            difference += is_leap_year(y) ? 366 : 365;
        }
        for (long m = 1; m < month; m++) difference += month_length(year, m);
        return (usz)(difference % 7);
    }
    for (long y = year; y < 1900; y++) {
        difference += is_leap_year(y) ? 366 : 365;
    }
    for (long m = 1; m < month; m++) difference -= month_length(1900, m);
    return (usz)((7 - difference % 7) % 7);
}

fn void write_cell(char* output, usz* position, long day) {
    if (day == 0) {
        for (usz i = 0; i < 4; i++) { output[position[0]] = ' '; position[0]++; }
    } else {
        if (day >= 10) {
            output[position[0]] = (char)('0' + day / 10); position[0]++;
            output[position[0]] = (char)('0' + day % 10); position[0]++;
            output[position[0]] = ' '; position[0]++;
            output[position[0]] = ' '; position[0]++;
        } else {
            output[position[0]] = (char)('0' + day); position[0]++;
            output[position[0]] = ' '; position[0]++;
            output[position[0]] = ' '; position[0]++;
            output[position[0]] = ' '; position[0]++;
        }
    }
}

fn long find_month_calendar(long* values, usz length, char* output, usz output_capacity)
    @export("find_month_calendar") {
    if (values == null || length != 2) return -1;
    long month = values[0];
    long year = values[1];
    if (month < 1 || month > 12 || year < MIN_YEAR || year > MAX_YEAR) return -1;

    usz offset = start_offset(month, year);
    usz total_cells = offset + (usz)month_length(year, month);
    usz required = 27 + total_cells * 4 + (total_cells + 6) / 7;
    if (required > MAX_OUTPUT_BYTES) return -1;
    if (output == null || output_capacity < required) return -2;

    char* header = "M   T   W   Th  F   S   Su\n";
    usz written = 0;
    for (usz i = 0; i < 27; i++) { output[written] = header[i]; written++; }
    usz cursor = 0;
    while (cursor < total_cells) {
        usz cells = total_cells - cursor;
        if (cells > 7) cells = 7;
        for (usz column = 0; column < cells; column++) {
            usz cell = cursor + column;
            long day = cell < offset ? 0 : (long)(cell - offset + 1);
            write_cell(output, &written, day);
        }
        output[written] = '\n'; written++;
        cursor += cells;
    }
    return (long)written;
}
