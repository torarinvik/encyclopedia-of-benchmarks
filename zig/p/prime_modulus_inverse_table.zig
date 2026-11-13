const modulus: i64 = 1_000_000_007;

export fn prime_modulus_inverse_table(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 34) return -1;
    if (input[0] < 0 or input[0] > 32) return -1;
    const count: usize = @intCast(input[0]);
    if (length != count + 1) return -1;
    var maximum: usize = 0;
    for (0..count) |i| {
        if (input[i + 1] < 1 or input[i + 1] > 256) return -1;
        maximum = @max(maximum, @as(usize, @intCast(input[i + 1])));
    }
    if (count == 0) return 0;
    const bytes = 4 * count;
    if (output == null or capacity < bytes) return -2;
    var inverse = [_]i64{0} ** 257;
    inverse[1] = 1;
    for (2..maximum + 1) |i| {
        const value: i64 = @intCast(i);
        const remainder: usize = @intCast(@mod(modulus, value));
        inverse[i] = modulus - @mod(@divTrunc(modulus, value) * inverse[remainder], modulus);
    }
    for (0..count) |i| {
        const operand: usize = @intCast(input[i + 1]);
        const value: u32 = @intCast(inverse[operand]);
        output[4*i] = @intCast(value & 255);
        output[4*i+1] = @intCast((value >> 8) & 255);
        output[4*i+2] = @intCast((value >> 16) & 255);
        output[4*i+3] = @intCast((value >> 24) & 255);
    }
    return @intCast(bytes);
}
