const std = @import("std");

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

/// Cross two bounded integer vectors and encode components plus magnitude.
export fn vector_cross_product(input: [*]const i64, input_length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (input_length != 6) return -1;
    for (0..6) |index| {
        if (input[index] < -1_000_000 or input[index] > 1_000_000) return -1;
    }
    const x = input[1] * input[5] - input[2] * input[4];
    const y = -((input[0] * input[5]) - (input[2] * input[3]));
    const z = input[0] * input[4] - input[1] * input[3];
    const magnitude = @sqrt(@as(f64, @floatFromInt(x)) * @as(f64, @floatFromInt(x)) +
        @as(f64, @floatFromInt(y)) * @as(f64, @floatFromInt(y)) +
        @as(f64, @floatFromInt(z)) * @as(f64, @floatFromInt(z)));
    const magnitude_micro: i64 = @intFromFloat(magnitude * 1_000_000.0 + 0.5);
    if (output_capacity < 32) return -2;
    storeI64Le(output, 0, x); storeI64Le(output, 8, y);
    storeI64Le(output, 16, z); storeI64Le(output, 24, magnitude_micro);
    return 32;
}
