export fn problem164(n_digits: i64) i64 {
    if (n_digits < 0 or n_digits > 26) return -1;
    if (n_digits == 0) return 1;

    var current = [_]i64{0} ** 100;
    var next = [_]i64{0} ** 100;
    for (1..10) |first| current[first * 10] = 1;

    var used: i64 = 1;
    while (used < n_digits) : (used += 1) {
        @memset(&next, 0);
        for (0..10) |previous| {
            for (0..10) |before_previous| {
                const ways = current[previous * 10 + before_previous];
                const maximum_digit = 9 - @as(i64, @intCast(previous)) - @as(i64, @intCast(before_previous));
                var digit: i64 = 0;
                while (digit <= maximum_digit) : (digit += 1) {
                    const slot: usize = @intCast(digit * 10 + @as(i64, @intCast(previous)));
                    next[slot] += ways;
                }
            }
        }
        current = next;
    }

    var total: i64 = 0;
    for (current) |ways| total += ways;
    return total;
}
