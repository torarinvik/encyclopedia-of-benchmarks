module fib2;

fn long fib2_value(long n) {
    if (n < 2L) return 1L;
    return fib2_value(n - 2L) + fib2_value(n - 1L);
}

fn long fib2(long n) @export("fib2") {
    if (n < 0L || n > 30L) return -1L;
    return fib2_value(n);
}
