module fibonacci_recursive;

fn long fibonacci_value(long n) {
    if (n < 2L) return n;
    return fibonacci_value(n - 1L) + fibonacci_value(n - 2L);
}

fn long fibonacci_recursive(long n) @export("fibonacci_recursive") {
    if (n < 0L || n > 30L) return -1L;
    return fibonacci_value(n);
}
