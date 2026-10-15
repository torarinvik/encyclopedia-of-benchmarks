export fn cake_numbers_sequence(n: i64) i64 {
    if (n < 0 or n > 2000000) return -1;
    return @divTrunc(n * n * n + 5 * n + 6, 6);
}
