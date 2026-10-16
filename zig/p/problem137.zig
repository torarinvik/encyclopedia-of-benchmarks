export fn problem137(n: i64) i64 {
    if (n < 1 or n > 23) return -1;
    var previous: i64 = 1;
    var current: i64 = 1;
    var index: i64 = 0;
    while (index < 2 * n - 1) : (index += 1) {
        const next = previous + current;
        previous = current;
        current = next;
    }
    return previous * current;
}
