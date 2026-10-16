package find_month_calendar

import "core:c"

MIN_YEAR :: i64(1899)
MAX_YEAR :: i64(2100)
MAX_OUTPUT_BYTES :: int(181)
HEADER :: "M   T   W   Th  F   S   Su\n"

is_leap_year :: proc "contextless" (year: i64) -> bool {
    return year % 400 == 0 || (year % 100 != 0 && year % 4 == 0)
}

month_length :: proc "contextless" (year, month: i64) -> int {
    if month == 2 && is_leap_year(year) do return 29
    if month == 2 do return 28
    if month == 4 || month == 6 || month == 9 || month == 11 do return 30
    return 31
}

start_offset :: proc "contextless" (month, year: i64) -> int {
    difference: i64 = 0
    if year >= 1900 {
        for y := i64(1900); y < year; y += 1 {
            if is_leap_year(y) { difference += 366 } else { difference += 365 }
        }
        for m := i64(1); m < month; m += 1 {
            difference += i64(month_length(year, m))
        }
        return int(difference % 7)
    }
    for y := year; y < 1900; y += 1 {
        if is_leap_year(y) { difference += 366 } else { difference += 365 }
    }
    for m := i64(1); m < month; m += 1 {
        difference -= i64(month_length(1900, m))
    }
    return int((7 - difference % 7) % 7)
}

write_byte :: proc "contextless" (output: [^]u8, position: ^int, value: u8) {
    output[position^] = value
    position^ += 1
}

write_cell :: proc "contextless" (output: [^]u8, position: ^int, day: int) {
    if day == 0 {
        for _ in 0 ..< 4 do write_byte(output, position, u8(32))
    } else if day >= 10 {
        write_byte(output, position, u8(48 + day / 10))
        write_byte(output, position, u8(48 + day % 10))
        write_byte(output, position, u8(32))
        write_byte(output, position, u8(32))
    } else {
        write_byte(output, position, u8(48 + day))
        write_byte(output, position, u8(32))
        write_byte(output, position, u8(32))
        write_byte(output, position, u8(32))
    }
}

@(export)
find_month_calendar :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length != 2 do return -1
    month, year := values[0], values[1]
    if month < 1 || month > 12 || year < MIN_YEAR || year > MAX_YEAR do return -1

    offset := start_offset(month, year)
    total_cells := offset + month_length(year, month)
    required := len(HEADER) + total_cells * 4 + (total_cells + 6) / 7
    if required > MAX_OUTPUT_BYTES do return -1
    if output == nil || output_capacity < c.size_t(required) do return -2

    position := 0
    header := HEADER
    for index := 0; index < len(header); index += 1 {
        write_byte(output, &position, header[index])
    }
    cursor := 0
    for cursor < total_cells {
        cells := min(7, total_cells - cursor)
        for column := 0; column < cells; column += 1 {
            cell := cursor + column
            day := 0
            if cell >= offset do day = cell - offset + 1
            write_cell(output, &position, day)
        }
        write_byte(output, &position, 10)
        cursor += cells
    }
    return i64(position)
}
