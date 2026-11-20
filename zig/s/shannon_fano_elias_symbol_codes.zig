pub export fn shannon_fano_elias_symbol_codes(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 10) return -1;
    const raw_n = input[0];
    if (raw_n < 1 or raw_n > 8 or length != @as(usize, @intCast(raw_n)) + 1) return -1;
    const n: usize = @intCast(raw_n);
    var total: i64 = 0;
    for (0..n) |i| {
        const weight = input[1+i];
        if (weight < 1 or weight > 15) return -1;
        total += weight;
    }
    if (total > 120) return -1;

    var staged: [17]u8 = @splat(0);
    staged[0] = @intCast(n);
    var prefix: i64 = 0;
    for (0..n) |i| {
        const weight = input[1+i];
        var bits: u32 = 1;
        while ((@as(i64, 1) << @intCast(bits - 1)) * weight < total) bits += 1;
        const numerator = (2 * prefix + weight) * (@as(i64, 1) << @intCast(bits - 1));
        const code: u8 = @intCast(@divTrunc(numerator, total));
        staged[1+2*i] = @intCast(bits);
        staged[2+2*i] = code << @intCast(8 - bits);
        prefix += weight;
    }
    const needed = 1 + 2*n;
    if (output == null or capacity < needed) return -2;
    for (0..needed) |i| output[i] = staged[i];
    return @intCast(needed);
}
