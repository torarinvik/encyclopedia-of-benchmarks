const MAX_N: usize = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_N + 4;
const MAX_OUTPUT_BYTES: usize = 8 * MAX_N;
const MAX_PLACES: i64 = 1_000_000;

export fn rotate_to_the_right(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const values = input.?;
    const n_value = values[0];
    const places = values[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or
        places < -MAX_PLACES or places > MAX_PLACES) return -1;
    const n: usize = @intCast(n_value);
    if (length != n + 2) return -1;
    for (0..n) |index| {
        const value = values[2 + index];
        if (value < -2147483648 or value > 2147483647) return -1;
    }

    const remainder = @rem(places, n_value);
    const shift: usize = @intCast(if (remainder < 0) remainder + n_value else remainder);
    const output_bytes = n * 8;
    if (output == null or output_capacity < output_bytes) return -2;

    var encoded: [MAX_OUTPUT_BYTES]u8 = undefined;
    for (0..n) |index| {
        const source = (index + n - shift) % n;
        const bits: u64 = @bitCast(values[2 + source]);
        for (0..8) |byte| encoded[index * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
    }
    @memcpy(output.?[0..output_bytes], encoded[0..output_bytes]);
    return @intCast(output_bytes);
}
