fn put_i64(out: [*c]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[at * 8 + b] = @truncate(bits >> @intCast(8 * b));
}

export fn approximate_tandem_squares(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 34) return -1;
    const n0 = input[0]; const budget = input[1];
    if (n0 < 2 or n0 > 32 or budget < 0 or budget > 8 or length != @as(usize, @intCast(n0)) + 2) return -1;
    const n: usize = @intCast(n0);
    for (0..n) |i| if (input[2 + i] < 0 or input[2 + i] > 3) return -1;
    var starts = [_]i64{0} ** 256;
    var periods = [_]i64{0} ** 256;
    var errors = [_]i64{0} ** 256;
    var count: usize = 0;
    for (0..n) |start| {
        var period: usize = 1;
        while (2 * period <= n - start) : (period += 1) {
            var mismatches: i64 = 0;
            for (0..period) |i| if (input[2 + start + i] != input[2 + start + period + i]) { mismatches += 1; };
            if (mismatches <= budget) {
                starts[count] = @intCast(start); periods[count] = @intCast(period); errors[count] = mismatches; count += 1;
            }
        }
    }
    const bytes = 8 * (1 + 3 * count);
    if (output == null or capacity < bytes) return -2;
    put_i64(output, 0, @intCast(count));
    for (0..count) |i| {
        put_i64(output, 1 + 3 * i, starts[i]); put_i64(output, 2 + 3 * i, periods[i]); put_i64(output, 3 + 3 * i, errors[i]);
    }
    return @intCast(bytes);
}
