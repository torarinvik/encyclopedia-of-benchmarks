/// Keep each value that is not smaller than the last retained value.
const MAX_INPUT_LENGTH: usize = 128;

fn store_i32_le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn stalin_sort(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (length > MAX_INPUT_LENGTH or (length != 0 and values == null)) return -1;
    for (0..length) |index| {
        const value = values[index];
        if (value < -2147483648 or value > 2147483647) return -1;
    }

    var kept: usize = 0;
    var last: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (kept == 0 or value >= last) {
            kept += 1;
            last = value;
        }
    }
    const output_bytes = kept * 4;
    if (output == null or output_capacity < output_bytes) return -2;

    var output_index: usize = 0;
    last = 0;
    for (0..length) |index| {
        const value = values[index];
        if (output_index == 0 or value >= last) {
            store_i32_le(output, output_index * 4, value);
            output_index += 1;
            last = value;
        }
    }
    return @intCast(output_bytes);
}
