/// Naive recursive Fibonacci on a deliberately small domain.
fn fibonacciValue(n: i64) i64 {
    if (n < 2) return n;
    return fibonacciValue(n - 1) + fibonacciValue(n - 2);
}

export fn fibonacci_recursive(n: i64) i64 {
    if (n < 0 or n > 30) return -1;
    return fibonacciValue(n);
}
