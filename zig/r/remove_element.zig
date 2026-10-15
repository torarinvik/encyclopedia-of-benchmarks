/// Remove every occurrence of target while preserving the surviving order.
const MAX_LENGTH: usize = 4096;

export fn remove_element(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (length == 0 or length > MAX_LENGTH or input == null) return -1;
    const target = input[0];
    if (target < -2147483648 or target > 2147483647) return -1;
    var survivor_count: usize = 0;
    for (1..length) |index| {
        const value = input[index];
        if (value < -2147483648 or value > 2147483647) return -1;
        if (value != target) survivor_count += 1;
    }
    const output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes or (output_bytes != 0 and output == null)) return -2;
    var written: usize = 0;
    for (1..length) |index| {
        const value = input[index];
        if (value != target) {
            const signed_value: i32 = @intCast(value);
            const bits: u32 = @bitCast(signed_value);
            for (0..4) |byte| {
                output[written * 4 + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
            }
            written += 1;
        }
    }
    if (written != survivor_count) return -1;
    return @intCast(written);
}
