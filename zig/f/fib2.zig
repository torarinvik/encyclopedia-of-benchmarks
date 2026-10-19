/// Shootout fib2: uncached recursion with fib(0) = fib(1) = 1.
fn fib2Value(n: i64) i64 {
    if (n < 2) return 1;
    return fib2Value(n - 2) + fib2Value(n - 1);
}

export fn fib2(n: i64) i64 {
    if (n < 0 or n > 30) return -1;
    return fib2Value(n);
}
