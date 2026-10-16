/// Portable byte-channel negative transform.
export fn convert_to_negative(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > 4096) return -1;
    const count_value = values[0];
    if (count_value < 0 or count_value > 4095 or @as(usize, @intCast(count_value)) != length - 1) return -1;
    const count: usize = @intCast(count_value);
    for (0..count) |index| {
        if (values[index + 1] < 0 or values[index + 1] > 255) return -1;
    }
    if (count > output_capacity or (count != 0 and output == null)) return -2;
    for (0..count) |index| output[index] = @intCast(255 - values[index + 1]);
    return count_value;
}
