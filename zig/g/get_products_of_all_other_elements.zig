const MAX_ARRAY_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 34;

fn writeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn get_products_of_all_other_elements(
    input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 or input[0] > MAX_ARRAY_LENGTH) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 1) return -1;
    var result: [MAX_ARRAY_LENGTH]i64 = @splat(0);
    for (0..n) |i| {
        if (input[i + 1] < -2 or input[i + 1] > 2) return -1;
    }
    if (n < 2) return 0;
    const output_bytes = n * 8;
    if (output == null or capacity < output_bytes) return -2;

    result[0] = 1;
    for (0..n - 1) |i| result[i + 1] = input[i + 1] * result[i];
    var suffix: i64 = 1;
    var i = n;
    while (i > 1) {
        i -= 1;
        const value = input[i + 1];
        result[i - 1] *= suffix * value;
        suffix *= value;
    }
    for (0..n) |index| writeI64Le(output, index * 8, result[index]);
    return @intCast(output_bytes);
}
