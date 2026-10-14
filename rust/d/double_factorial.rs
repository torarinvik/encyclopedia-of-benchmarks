/// Iterative double factorial for the signed 64-bit benchmark contract.
#[no_mangle]
pub extern "C" fn double_factorial(n: i64) -> i64 {
    if !(0..=33).contains(&n) {
        return -1;
    }
    let mut product = 1i64;
    let mut factor = n;
    while factor > 1 {
        product *= factor;
        factor -= 2;
    }
    product
}
