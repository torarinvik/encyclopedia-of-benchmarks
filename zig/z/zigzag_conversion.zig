const MAX_INPUT_LENGTH: usize = 1025;
const MAX_ROWS: i64 = 1024;

fn is_ascii_letter(value: i64) bool {
    return (value >= 65 and value <= 90) or (value >= 97 and value <= 122);
}

export fn zigzag_conversion(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > MAX_INPUT_LENGTH) return -1;
    const rows_value = values[0];
    if (rows_value < 1 or rows_value > MAX_ROWS) return -1;
    const text_length = length - 1;
    for (0..text_length) |index| {
        if (!is_ascii_letter(values[index + 1])) return -1;
    }
    if (output_capacity < text_length) return -2;
    if (text_length == 0) return 0;
    const rows: usize = @intCast(rows_value);
    if (rows == 1 or rows >= text_length) {
        for (0..text_length) |index| output[index] = @intCast(values[index + 1]);
        return @intCast(text_length);
    }
    const cycle = 2 * (rows - 1);
    var written: usize = 0;
    for (0..rows) |row| {
        var index = row;
        var step = if (row == 0 or row + 1 == rows) cycle else cycle - 2 * row;
        while (index < text_length) {
            output[written] = @intCast(values[index + 1]);
            written += 1;
            index += step;
            if (row > 0 and row + 1 < rows) step = cycle - step;
        }
    }
    return @intCast(written);
}
