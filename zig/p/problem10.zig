export fn problem10(limit: i64) i64 {
    if (limit < 0 or limit > 2_000_000) return -1;
    var composite = [_]bool{false} ** 1_000_000;
    const odd_count: usize = @intCast(@divTrunc(limit, 2));
    var total: i64 = if (limit > 2) 2 else 0;
    var prime: i64 = 3;
    while (prime * prime < limit) : (prime += 2) {
        if (!composite[@intCast(@divTrunc(prime, 2))]) {
            var index: i64 = @divTrunc(prime * prime, 2);
            while (index < odd_count) : (index += prime) {
                composite[@intCast(index)] = true;
            }
        }
    }
    for (1..odd_count) |index| {
        if (!composite[index]) total += @intCast(2 * index + 1);
    }
    return total;
}
