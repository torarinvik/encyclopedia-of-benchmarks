#[no_mangle]
pub extern "C" fn check_factorial(n: i64) -> i64 {
    if n <= 0 { return 0; }
    let mut value = n;
    let mut divisor = 2i64;
    while value % divisor == 0 {
        value /= divisor;
        divisor += 1;
    }
    if value == 1 { 1 } else { 0 }
}
