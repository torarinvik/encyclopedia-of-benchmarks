fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

/// Sort up to ten bounded values and encode quartile statistics.
export fn quartile(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 11) return -1;
    const count_value = input[0];
    if (count_value < 1 or count_value > 10) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 1) return -1;
    var values: [10]i64 = [_]i64{0} ** 10;
    for (0..count) |index| {
        if (input[index + 1] < 0 or input[index + 1] > 99) return -1;
        values[index] = input[index + 1];
    }
    for (0..count) |i| {
        for (0..count) |j| {
            if (values[i] < values[j]) { const tmp = values[i]; values[i] = values[j]; values[j] = tmp; }
        }
    }
    const q1 = values[count / 4];
    const q3 = values[(3 * count) / 4];
    const required = (count + 4) * 8;
    if (output_capacity < required) return -2;
    storeI64Le(output, 0, count_value);
    for (0..count) |index| storeI64Le(output, 8 * (index + 1), values[index]);
    storeI64Le(output, 8 * (count + 1), q1);
    storeI64Le(output, 8 * (count + 2), q3);
    storeI64Le(output, 8 * (count + 3), q3 - q1);
    return @intCast(required);
}
