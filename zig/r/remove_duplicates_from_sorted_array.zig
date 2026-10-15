/// Compact each value in an ascending array to its first occurrence.
const MAX_LENGTH: usize = 4096;

export fn remove_duplicates_from_sorted_array(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (length > MAX_LENGTH or (length != 0 and input == null)) return -1;
    var unique_count: usize = 0;
    for (0..length) |index| {
        const value = input[index];
        if (value < -2147483648 or value > 2147483647 or
            (index > 0 and input[index - 1] > value)) return -1;
        if (index == 0 or input[index - 1] != value) unique_count += 1;
    }
    const output_bytes = unique_count * 4;
    if (output_capacity < output_bytes or (output_bytes != 0 and output == null)) return -2;
    var written: usize = 0;
    for (0..length) |index| {
        const value = input[index];
        if (index == 0 or input[index - 1] != value) {
            const signed_value: i32 = @intCast(value);
            const bits: u32 = @bitCast(signed_value);
            for (0..4) |byte| {
                output[written * 4 + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
            }
            written += 1;
        }
    }
    if (written != unique_count) return -1;
    return @intCast(written);
}
