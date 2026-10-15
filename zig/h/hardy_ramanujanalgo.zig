/// Count distinct prime divisors using factor-2 removal and odd trial divisors.
export fn hardy_ramanujanalgo(value: i64) i64 {
    if (value < 1 or value > 2_147_483_647) return -1;

    var remaining = value;
    var count: i64 = 0;
    if (@rem(remaining, 2) == 0) count += 1;
    while (@rem(remaining, 2) == 0) {
        remaining = @divTrunc(remaining, 2);
    }

    var factor: i64 = 3;
    while (factor <= @divTrunc(remaining, factor)) : (factor += 2) {
        if (@rem(remaining, factor) == 0) {
            count += 1;
            while (@rem(remaining, factor) == 0) {
                remaining = @divTrunc(remaining, factor);
            }
        }
    }
    if (remaining > 2) count += 1;
    return count;
}
