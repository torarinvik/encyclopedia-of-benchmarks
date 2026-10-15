/// Naive recursive Fibonacci on a deliberately small domain.
fn fibonacci_value(n: i64) -> i64 {
    if n < 2 { return n; }
    fibonacci_value(n - 1) + fibonacci_value(n - 2)
}

#[no_mangle]
pub extern "C" fn fibonacci_recursive(n: i64) -> i64 {
    if !(0..=30).contains(&n) { return -1; }
    fibonacci_value(n)
}
