const MIN_YEAR: i64 = 1899;
const MAX_YEAR: i64 = 2100;
const MAX_OUTPUT_BYTES: usize = 181;
const HEADER = "M   T   W   Th  F   S   Su\n";

fn isLeapYear(year: i64) bool {
    return @mod(year, 400) == 0 or (@mod(year, 100) != 0 and @mod(year, 4) == 0);
}

fn monthLength(year: i64, month: i64) usize {
    if (month == 2 and isLeapYear(year)) return 29;
    return switch (month) {
        2 => 28,
        4, 6, 9, 11 => 30,
        else => 31,
    };
}

fn startOffset(month: i64, year: i64) usize {
    var difference: i64 = 0;
    if (year >= 1900) {
        var current_year: i64 = 1900;
        while (current_year < year) : (current_year += 1) {
            difference += if (isLeapYear(current_year)) 366 else 365;
        }
        var current_month: i64 = 1;
        while (current_month < month) : (current_month += 1) {
            difference += @intCast(monthLength(year, current_month));
        }
        return @intCast(@mod(difference, 7));
    }
    var current_year = year;
    while (current_year < 1900) : (current_year += 1) {
        difference += if (isLeapYear(current_year)) 366 else 365;
    }
    var current_month: i64 = 1;
    while (current_month < month) : (current_month += 1) {
        difference -= @intCast(monthLength(1900, current_month));
    }
    return @intCast(@mod(7 - @mod(difference, 7), 7));
}

fn writeByte(output: [*]u8, position: *usize, value: u8) void {
    output[position.*] = value;
    position.* += 1;
}

fn writeCell(output: [*]u8, position: *usize, day: usize) void {
    if (day == 0) {
        for (0..4) |_| writeByte(output, position, ' ');
    } else if (day >= 10) {
        writeByte(output, position, '0' + @as(u8, @intCast(day / 10)));
        writeByte(output, position, '0' + @as(u8, @intCast(day % 10)));
        writeByte(output, position, ' ');
        writeByte(output, position, ' ');
    } else {
        writeByte(output, position, '0' + @as(u8, @intCast(day)));
        writeByte(output, position, ' ');
        writeByte(output, position, ' ');
        writeByte(output, position, ' ');
    }
}

export fn find_month_calendar(values: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length != 2) return -1;
    const input = values.?;
    const month = input[0];
    const year = input[1];
    if (month < 1 or month > 12 or year < MIN_YEAR or year > MAX_YEAR) return -1;

    const offset = startOffset(month, year);
    const total_cells = offset + monthLength(year, month);
    const required = HEADER.len + total_cells * 4 + (total_cells + 6) / 7;
    if (required > MAX_OUTPUT_BYTES) return -1;
    if (output == null or output_capacity < required) return -2;

    const result = output.?;
    var written: usize = 0;
    for (HEADER) |byte| writeByte(result, &written, byte);
    var cursor: usize = 0;
    while (cursor < total_cells) {
        const cells = @min(7, total_cells - cursor);
        for (0..cells) |column| {
            const cell = cursor + column;
            const day = if (cell < offset) 0 else cell - offset + 1;
            writeCell(result, &written, day);
        }
        writeByte(result, &written, '\n');
        cursor += cells;
    }
    return @intCast(written);
}
