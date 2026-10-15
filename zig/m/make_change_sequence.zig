export fn make_change_sequence(amount: i64) i64 {
    if (amount < 0 or amount > 128) return -1;
    var values: [129]i64 = [_]i64{0} ** 129;
    const seed = [_]i64{ 1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 11, 12, 15, 16, 19, 22, 25 };
    @memcpy(values[0..17], &seed);
    var n: i64 = 17;
    while (n <= amount) : (n += 1) {
        const index: usize = @intCast(n);
        values[index] = values[@intCast(n - 2)] + values[@intCast(n - 5)] - values[@intCast(n - 7)]
                      + values[@intCast(n - 10)] - values[@intCast(n - 12)] - values[@intCast(n - 15)]
                      + values[@intCast(n - 17)] + 1;
    }
    return values[@intCast(amount)];
}
