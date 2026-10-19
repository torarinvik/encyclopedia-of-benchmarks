/// Shootout fib2: uncached recursion with fib(0) = fib(1) = 1.
fn fib2_value(n: i64) -> i64 {
    if n < 2 { return 1; }
    fib2_value(n - 2) + fib2_value(n - 1)
}

#[no_mangle]
pub extern "C" fn fib2(n: i64) -> i64 {
    if !(0..=30).contains(&n) { return -1; }
    fib2_value(n)
}
