fn isComposite(bits: []u64, value: i64) bool {
    const word: usize = @intCast(value >> 6);
    const shift: u6 = @intCast(value & 63);
    return (bits[word] & (@as(u64, 1) << shift)) != 0;
}
fn markComposite(bits: []u64, value: i64) void {
    const word: usize = @intCast(value >> 6);
    const shift: u6 = @intCast(value & 63);
    bits[word] |= @as(u64, 1) << shift;
}

export fn problem800(base: i64, degree: i64) i64 {
    if (base < 2 or base > 1_000_000 or degree < 1 or degree > 1_000_000) return -1;
    const upper_bound = @as(f64, @floatFromInt(degree)) * @log2(@as(f64, @floatFromInt(base)));
    const prime_limit: i64 = @intFromFloat(upper_bound);
    if (prime_limit <= 2) return 0;
    const allocator = std.heap.page_allocator;
    const composite = allocator.alloc(u64, @intCast(@divTrunc(prime_limit + 63, 64))) catch return -1;
    defer allocator.free(composite);
    @memset(composite, 0);
    var prime: i64 = 2;
    while (prime <= @divTrunc(prime_limit - 1, prime)) : (prime += 1) {
        if (isComposite(composite, prime)) continue;
        var multiple = prime * prime;
        while (multiple < prime_limit) : (multiple += prime) markComposite(composite, multiple);
    }

    var right_value: i64 = 0;
    var prime_count: i64 = 0;
    var value: i64 = 2;
    while (value < prime_limit) : (value += 1) {
        if (!isComposite(composite, value)) { right_value = value; prime_count += 1; }
    }
    if (prime_count < 2) return 0;

    var right_rank = prime_count - 1;
    var left_rank: i64 = 0;
    var left_value: i64 = 2;
    var count: i64 = 0;
    while (left_rank < right_rank) {
        while (isComposite(composite, left_value)) left_value += 1;
        const left_log = @log2(@as(f64, @floatFromInt(left_value)));
        while (@as(f64, @floatFromInt(right_value)) * left_log
            + @as(f64, @floatFromInt(left_value)) * @log2(@as(f64, @floatFromInt(right_value))) > upper_bound) {
            right_rank -= 1;
            right_value -= 1;
            while (right_value >= 2 and isComposite(composite, right_value)) right_value -= 1;
        }
        count += right_rank - left_rank;
        left_rank += 1;
        left_value += 1;
    }
    return count;
}
