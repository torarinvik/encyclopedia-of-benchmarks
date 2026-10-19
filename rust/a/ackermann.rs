/// Bounded recursive Ackermann function A(m, n).
fn ackermann_value(m: i64, n: i64) -> i64 {
    if m == 0 { return n + 1; }
    if n == 0 { return ackermann_value(m - 1, 1); }
    ackermann_value(m - 1, ackermann_value(m, n - 1))
}

#[no_mangle]
pub extern "C" fn ackermann(m: i64, n: i64) -> i64 {
    if m < 0 || m > 3 || n < 0 || n > 8 { return -1; }
    ackermann_value(m, n)
}
