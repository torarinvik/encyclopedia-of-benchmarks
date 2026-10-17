fn collatzLength(start: u64) u64 {
    var current = start;
    var length: u64 = 1;
    while (current != 1) {
        if (length >= 10_000) return 0;
        if (current % 2 == 0) {
            current /= 2;
        } else {
            if (current > 3_002_399_751_580_330) return 0;
            current = 3 * current + 1;
        }
        length += 1;
    }
    return length;
}

export fn problem014(limit: i64) i64 {
    if (limit < 1 or limit > 1_000_000) return -1;
    var best_start: u64 = 1;
    var best_length: u64 = 1;
    var start: u64 = 2;
    while (start < @as(u64, @intCast(limit))) : (start += 1) {
        const length = collatzLength(start);
        if (length == 0) return -1;
        if (length > best_length) {
            best_start = start;
            best_length = length;
        }
    }
    return @intCast(best_start);
}
