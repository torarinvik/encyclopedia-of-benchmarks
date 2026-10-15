/// Return the exact scaled lower bound produced by arithmetic coding.
export fn arithmetic_coding(input: [*]const i64, length: usize) i64 {
    if (length < 2) return -1;
    const count = input[0];
    if (count < 1 or count > 12 or length != @as(usize, @intCast(count + 1))) return -1;

    var frequency: [256]i64 = @splat(0);
    var cumulative: [257]i64 = @splat(0);
    for (0..@intCast(count)) |index| {
        const symbol = input[index + 1];
        if (symbol < 0 or symbol > 255) return -1;
        frequency[@intCast(symbol)] += 1;
    }
    for (0..256) |symbol| {
        cumulative[symbol + 1] = cumulative[symbol] + frequency[symbol];
    }

    var low: i64 = 0;
    var high: i64 = 1;
    for (0..@intCast(count)) |index| {
        const symbol: usize = @intCast(input[index + 1]);
        const range = high - low;
        const base = low * count;
        high = base + range * cumulative[symbol + 1];
        low = base + range * cumulative[symbol];
    }
    return low;
}
