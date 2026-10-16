export fn problem1(limit: i64) i64 {
    if (limit < 0 or limit > 100_000) return -1;
    var total: i64 = 0;
    var value: i64 = 1;
    while (value < limit) : (value += 1) {
        if (@rem(value, 3) == 0 or @rem(value, 5) == 0) total += value;
    }
    return total;
}
