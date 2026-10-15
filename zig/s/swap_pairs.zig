/// Swap adjacent node values in a bounded array representation of a list.
const MAX_LENGTH: usize = 1024;

export fn swap_pairs(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (length > MAX_LENGTH or (length != 0 and input == null)) return -1;
    for (0..length) |index| {
        if (input[index] < -2147483648 or input[index] > 2147483647) return -1;
    }
    const output_bytes = length * 4;
    if (output_capacity < output_bytes or (output_bytes != 0 and output == null)) return -2;

    for (0..length) |index| {
        const pair_start = (index / 2) * 2;
        const source_index = if (index % 2 == 0 and pair_start + 1 < length) pair_start + 1 else pair_start;
        const signed_value: i32 = @intCast(input[source_index]);
        const bits: u32 = @bitCast(signed_value);
        for (0..4) |byte| {
            output[index * 4 + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
        }
    }
    return @intCast(length);
}
