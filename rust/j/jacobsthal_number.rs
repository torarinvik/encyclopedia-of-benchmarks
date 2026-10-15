/// Return J(n) for the bounded signed-64-bit Jacobsthal index.
#[no_mangle]
pub extern "C" fn jacobsthal_number(n: i64) -> i64 {
    if !(0..=64).contains(&n) {
        return -1;
    }
    if n == 0 {
        return 0;
    }
    let mut previous = 0i64;
    let mut current = 1i64;
    for _ in 2..=n {
        let next = current + 2 * previous;
        previous = current;
        current = next;
    }
    current
}
