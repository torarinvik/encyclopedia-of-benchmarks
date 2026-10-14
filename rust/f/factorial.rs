/// Iterative factorial for the shared signed 64-bit benchmark contract.
#[no_mangle]
pub extern "C" fn factorial(n: i64) -> i64 {
    if !(0..=20).contains(&n) {
        return -1;
    }

    let mut product = 1i64;
    let mut factor = 2i64;
    while factor <= n {
        product *= factor;
        factor += 1;
    }
    product
}
