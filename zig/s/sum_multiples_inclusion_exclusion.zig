export fn sum_multiples_inclusion_exclusion(limit: i64) i64 {
    if (limit < 1 or limit > 100_000) return -1;
    const last = limit - 1;
    const threes = @divTrunc(last, 3);
    const fives = @divTrunc(last, 5);
    const fifteens = @divTrunc(last, 15);
    return @divTrunc(3 * threes * (threes + 1), 2)
        + @divTrunc(5 * fives * (fives + 1), 2)
        - @divTrunc(15 * fifteens * (fifteens + 1), 2);
}
