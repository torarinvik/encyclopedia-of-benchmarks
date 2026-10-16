const MAX_RUNES: usize = 8;
const MAX_INPUT_LENGTH: usize = MAX_RUNES + 2;
const BYTES_PER_VALUE: usize = 4;

fn isUnicodeScalar(value: i64) bool {
    return value >= 0 and value <= 0x10ffff and !(value >= 0xd800 and value <= 0xdfff);
}

fn storeU32Le(output: [*c]u8, position: usize, value: u32) void {
    for (0..BYTES_PER_VALUE) |byte| output[position + byte] = @truncate(value >> @as(u5, @intCast(byte * 8)));
}

fn emitRow(current: *[MAX_RUNES]i32, length: usize, output: [*c]u8,
    output_cursor: *usize, row_count: *usize) void {
    storeU32Le(output, output_cursor.*, @intCast(length));
    output_cursor.* += BYTES_PER_VALUE;
    for (0..length) |item| {
        storeU32Le(output, output_cursor.*, @bitCast(current[item]));
        output_cursor.* += BYTES_PER_VALUE;
    }
    row_count.* += 1;
}

fn generate(values: *[MAX_RUNES]i32, n: usize, start: usize,
    current: *[MAX_RUNES]i32, current_length: usize, output: [*c]u8,
    output_cursor: *usize, row_count: *usize) void {
    for (start..n) |index| {
        current[current_length] = values[index];
        emitRow(current, current_length + 1, output, output_cursor, row_count);
        generate(values, n, index + 1, current, current_length + 1,
                 output, output_cursor, row_count);
    }
}

export fn non_empty_subsequences(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const count_value = input[0];
    if (count_value < 1 or count_value > MAX_RUNES or length != @as(usize, @intCast(count_value)) + 1) return -1;
    const n: usize = @intCast(count_value);
    var values: [MAX_RUNES]i32 = undefined;
    for (0..n) |index| {
        const value = input[index + 1];
        if (!isUnicodeScalar(value)) return -1;
        values[index] = @intCast(value);
    }

    const rows = (@as(usize, 1) << n) - 1;
    const value_count = n * (@as(usize, 1) << (n - 1));
    const required = (rows + value_count) * BYTES_PER_VALUE;
    if (output_capacity < required or output == null) return -2;

    var current: [MAX_RUNES]i32 = undefined;
    var output_cursor: usize = 0;
    var emitted: usize = 0;
    generate(&values, n, 0, &current, 0, output, &output_cursor, &emitted);
    return @intCast(emitted);
}
