fn putI64(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn next_fit_bin_packing(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 1 or length > 65) return -1;
    const n0 = input[0];
    if (n0 < 0 or n0 > 64 or length != 1 + @as(usize, @intCast(n0))) return -1;
    const n: usize = @intCast(n0);
    for (0..n) |i| if (input[i + 1] < 1 or input[i + 1] > 1_000_000) return -1;
    var assignments = [_]i64{0} ** 64;
    var bins: i64 = 0;
    var remaining: i64 = 0;
    for (0..n) |i| {
        const size = input[i + 1];
        if (bins == 0 or size > remaining) {
            assignments[i] = bins;
            bins += 1;
            remaining = 1_000_000 - size;
        } else {
            assignments[i] = bins - 1;
            remaining -= size;
        }
    }
    const bytes = 8 * (n + 1);
    const output = output_opt orelse return -2;
    if (capacity < bytes) return -2;
    putI64(output, 0, bins);
    for (0..n) |i| putI64(output, i + 1, assignments[i]);
    return @intCast(bytes);
}
