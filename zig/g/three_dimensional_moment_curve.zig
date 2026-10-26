const MaxOutput = 1544;
fn putI64(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn three_dimensional_moment_curve(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 64) return -1;
    const n: usize = @intCast(input[0]); const bytes = 8 * (1 + 3 * n);
    if (output_opt == null or capacity < bytes) return -2;
    var staged: [MaxOutput]u8 = @splat(0); putI64(&staged, 0, @intCast(n));
    for (1..n + 1) |i| {
        const x: i64 = @intCast(i); const offset = 8 * (1 + 3 * (i - 1));
        putI64(&staged, offset, x); putI64(&staged, offset + 8, x * x); putI64(&staged, offset + 16, x * x * x);
    }
    const output = output_opt.?; @memcpy(output[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
