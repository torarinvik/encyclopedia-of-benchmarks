/// Iterative extended Euclid for positive signed-32-bit inputs.
fn storeI32(value: i64, output: [*c]u8, position: usize) usize {
    const magnitude: u64 = @intCast(if (value < 0) -value else value);
    var bits = magnitude;
    if (value < 0) bits = (1 << 32) - magnitude;
    for (0..4) |byte| {
        output[position + byte] = @intCast(bits % 256);
        bits /= 256;
    }
    return position + 4;
}

export fn extended_euclidean_algorithm(input: [*c]const i64, length: usize,
                                       output: [*c]u8, output_capacity: usize) i64 {
    if (length != 2) return -1;
    const first = input[0];
    const second = input[1];
    if (first < 1 or first > 2147483647 or second < 1 or second > 2147483647) return -1;
    if (output_capacity < 12) return -2;

    var old_r = first;
    var remainder = second;
    var old_x: i64 = 1;
    var x: i64 = 0;
    var old_y: i64 = 0;
    var y: i64 = 1;
    while (remainder != 0) {
        const quotient = @divTrunc(old_r, remainder);
        const next_r = old_r - quotient * remainder;
        old_r = remainder;
        remainder = next_r;
        const next_x = old_x - quotient * x;
        old_x = x;
        x = next_x;
        const next_y = old_y - quotient * y;
        old_y = y;
        y = next_y;
    }
    if (old_r > 2147483647 or old_x < -2147483648 or old_x > 2147483647 or
        old_y < -2147483648 or old_y > 2147483647) return -1;
    var written = storeI32(old_r, output, 0);
    written = storeI32(old_x, output, written);
    written = storeI32(old_y, output, written);
    if (written == 12) return 3;
    return -1;
}
