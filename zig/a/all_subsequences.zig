/// Emit subsequences in skip-before-include depth-first order.
const MAX_LENGTH: usize = 8;
const BYTES_PER_VALUE: usize = 4;

fn storeU32Le(output: [*]u8, position: usize, value: u32) void {
    for (0..4) |byte| output[position + byte] = @truncate(value >> @as(u5, @intCast(byte * 8)));
}

fn storeI32Le(output: [*]u8, position: usize, value: i32) void {
    storeU32Le(output, position, @bitCast(value));
}

fn generate(values: *[MAX_LENGTH]i32, n: usize, index: usize,
    current: *[MAX_LENGTH]i32, current_length: usize,
    output: [*]u8, output_cursor: *usize, result_count: *usize) void {
    if (index == n) {
        storeU32Le(output, output_cursor.*, @intCast(current_length));
        output_cursor.* += BYTES_PER_VALUE;
        for (0..current_length) |item| {
            storeI32Le(output, output_cursor.*, current[item]);
            output_cursor.* += BYTES_PER_VALUE;
        }
        result_count.* += 1;
        return;
    }
    generate(values, n, index + 1, current, current_length, output, output_cursor, result_count);
    current[current_length] = values[index];
    generate(values, n, index + 1, current, current_length + 1, output, output_cursor, result_count);
}

export fn all_subsequences(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > MAX_LENGTH + 1) return -1;
    const n_value = input[0];
    if (n_value < 0 or n_value > MAX_LENGTH or length != @as(usize, @intCast(n_value)) + 1) return -1;
    const n: usize = @intCast(n_value);
    var values: [MAX_LENGTH]i32 = undefined;
    for (0..n) |index| {
        const value = input[index + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
        values[index] = @intCast(value);
    }
    var result_count: usize = 1;
    for (0..n) |_| result_count *= 2;
    const value_count = if (n == 0) 0 else n * (result_count / 2);
    const required = (result_count + value_count) * BYTES_PER_VALUE;
    if (output_capacity < required) return -2;
    var current: [MAX_LENGTH]i32 = undefined;
    var output_cursor: usize = 0;
    var emitted: usize = 0;
    generate(&values, n, 0, &current, 0, output, &output_cursor, &emitted);
    return @intCast(emitted);
}
