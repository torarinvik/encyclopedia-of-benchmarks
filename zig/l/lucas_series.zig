export fn lucas_series(n: i64) i64 {
    if (n < 0 or n > 90) return -1;
    if (n == 0) return 2;
    var previous: i64 = 2;
    var current: i64 = 1;
    var index: i64 = 2;
    while (index <= n) : (index += 1) { const next = previous + current; previous = current; current = next; }
    return current;
}
