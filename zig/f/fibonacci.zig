/// Iterative Fibonacci for the shared signed 64-bit benchmark contract.
export fn fibonacci(n: i64) i64 {
    if (n < 0 or n > 92) return -1;
    if (n == 0) return 0;

    var previous: i64 = 0;
    var current: i64 = 1;
    var index: i64 = 1;
    while (index < n) : (index += 1) {
        const next = previous + current;
        previous = current;
        current = next;
    }
    return current;
}
