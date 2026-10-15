/// Return J(n) for the bounded signed-64-bit Jacobsthal index.
export fn jacobsthal_number(n: i64) i64 {
    if (n < 0 or n > 64) return -1;
    if (n == 0) return 0;
    var previous: i64 = 0;
    var current: i64 = 1;
    var index: i64 = 2;
    while (index <= n) : (index += 1) {
        const next = current + 2 * previous;
        previous = current;
        current = next;
    }
    return current;
}
