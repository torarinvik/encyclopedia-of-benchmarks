export fn fib(n: i64) i64 {
    if (n < 0 or n > 90) return -1;
    var previous: i64 = 1;
    var current: i64 = 2;
    var i: i64 = 0;
    while (i < n) : (i += 1) {
        const next = previous + current;
        previous = current;
        current = next;
    }
    return previous;
}
