fn put_i64(out: [*c]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[at * 8 + b] = @truncate(bits >> @intCast(8 * b));
}

export fn first_fit_cardinality_bin_packing(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > 35) return -1;
    const n0 = input[0]; const item_limit = input[1]; const cap = input[2];
    if (n0 < 1 or n0 > 32 or item_limit < 1 or item_limit > 32 or cap < 1 or cap > 10000 or length != @as(usize, @intCast(n0)) + 3) return -1;
    const n: usize = @intCast(n0);
    for (0..n) |i| if (input[3+i] < 1 or input[3+i] > cap) return -1;
    var loads = [_]i64{0} ** 32; var used = [_]i64{0} ** 32; var owners = [_]i64{0} ** 32;
    var bins: usize = 0;
    for (0..n) |i| {
        const size = input[3+i]; var b: usize = 0;
        while (b < bins and (used[b] >= item_limit or loads[b] > cap - size)) : (b += 1) {}
        if (b == bins) bins += 1;
        loads[b] += size; used[b] += 1; owners[i] = @intCast(b);
    }
    const bytes = 8 * (n + 1);
    if (output == null or capacity < bytes) return -2;
    put_i64(output, 0, @intCast(bins));
    for (0..n) |i| put_i64(output, i+1, owners[i]);
    return @intCast(bytes);
}
