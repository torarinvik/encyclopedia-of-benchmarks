const max_abs_component: i64 = 1_000_000;
const output_bytes = 16;

fn magnitude(value: i64) u64 {
    return if (value < 0) @intCast(-value) else @intCast(value);
}

fn gcdPositive(a: u64, b: u64) u64 {
    var x = a;
    var y = b;
    while (y != 0) { const remainder = x % y; x = y; y = remainder; }
    return x;
}

fn putI64Le(output: *[output_bytes]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn simplify_fraction(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length != 2) return -1;
    const numerator = values[0];
    const denominator = values[1];
    if (numerator < -max_abs_component or numerator > max_abs_component or
        denominator < -max_abs_component or denominator > max_abs_component or denominator == 0) return -1;
    const divisor: i64 = @intCast(gcdPositive(magnitude(numerator), magnitude(denominator)));
    const reduced_numerator = @divTrunc(numerator, divisor);
    const reduced_denominator = @divTrunc(denominator, divisor);
    var staged: [output_bytes]u8 = undefined;
    putI64Le(&staged, 0, reduced_numerator);
    putI64Le(&staged, 8, reduced_denominator);
    const out = output orelse return -2;
    if (capacity < output_bytes) return -2;
    @memcpy(out[0..output_bytes], staged[0..output_bytes]);
    return output_bytes;
}
