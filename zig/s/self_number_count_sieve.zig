const MAX_LIMIT: i64 = 100000;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn digitSum10(value: i64) i64 {
    var remaining = value;
    var sum: i64 = 0;
    while (remaining > 0) {
        sum += @mod(remaining, 10);
        remaining = @divTrunc(remaining, 10);
    }
    return sum;
}

export fn self_number_count_sieve(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const limit = input[0];
    if (length != 1 or limit < 1 or limit > MAX_LIMIT) return -1;

    var generated: [1563]u64 = @splat(0);
    var source: i64 = 1;
    while (source <= limit) : (source += 1) {
        const target = source + digitSum10(source);
        if (target <= limit) generated[@intCast(target / 64)] |= @as(u64, 1) << @intCast(@mod(target, 64));
    }
    var count: i64 = 0;
    var value: i64 = 1;
    while (value <= limit) : (value += 1) {
        const mask = @as(u64, 1) << @intCast(@mod(value, 64));
        if ((generated[@intCast(value / 64)] & mask) == 0) count += 1;
    }
    return count;
}
