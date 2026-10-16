export fn problem53(unused: i64) i64 {
    if (unused != 0) return -1;
    var total: i64 = 0;
    for (1..101) |n| {
        var coefficient: i64 = 1;
        for (1..(n/2 + 1)) |r| {
            coefficient = @divTrunc(coefficient * @as(i64, @intCast(n-r+1)), @as(i64, @intCast(r)));
            if (coefficient > 1_000_000) { total += @as(i64, @intCast(n-2*r+1)); break; }
        }
    }
    return total;
}
