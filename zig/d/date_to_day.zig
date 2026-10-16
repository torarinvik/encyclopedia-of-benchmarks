/// Return the English weekday name for a bounded ASCII d/m/yyyy date.
export fn date_to_day(input: [*c]const i64, length: usize,
                      output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 9 or length > 11 or input[length - 1] != 0) return -1;
    const date_length = length - 1;
    var cursor: usize = 0;
    var fields: [3]i64 = .{0, 0, 0};
    for (0..3) |field| {
        const start = cursor;
        var value: i64 = 0;
        while (cursor < date_length and input[cursor] >= 48 and input[cursor] <= 57) : (cursor += 1) {
            value = value * 10 + input[cursor] - 48;
        }
        const digits = cursor - start;
        const max_digits: usize = if (field == 2) 4 else 2;
        if (digits == 0 or digits > max_digits or (field == 2 and digits != 4)) return -1;
        fields[field] = value;
        if (field < 2) {
            if (cursor >= date_length or input[cursor] != 47) return -1;
            cursor += 1;
        }
    }
    if (cursor != date_length) return -1;
    const day: i64 = fields[0];
    const month: i64 = fields[1];
    const year: i64 = fields[2];
    if (year < 1 or year > 9999 or month < 1 or month > 12 or day < 1) return -1;
    const leap = year % 400 == 0 or (year % 4 == 0 and year % 100 != 0);
    const month_days = [_]i64{31, if (leap) 29 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if (day > month_days[@intCast(month - 1)]) return -1;

    var adjusted_year: i64 = year;
    var adjusted_month: i64 = month;
    if (adjusted_month < 3) { adjusted_year -= 1; adjusted_month += 12; }
    const year_of_century = @rem(adjusted_year, 100);
    const century = @divTrunc(adjusted_year, 100);
    const weekday = @rem(day + @divTrunc((adjusted_month + 1) * 26, 10) + year_of_century +
        @divTrunc(year_of_century, 4) + @divTrunc(century, 4) + 5 * century, 7);
    const names = [_][]const u8{"Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"};
    const name = names[@intCast(weekday)];
    if (output_capacity < name.len or output == null) return -2;
    for (name, 0..) |byte, index| output[index] = byte;
    return @intCast(name.len);
}
