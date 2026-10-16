/// Match the pinned source: odd exponents return F(exponent + 2) - 1.
#[no_mangle]
pub extern "C" fn problem301(exponent: i64) -> i64 {
    if !(0..=30).contains(&exponent) { return -1; }
    let mut previous = 0i64;
    let mut current = 1i64;
    for _ in 0..(exponent + 2) {
        let next = previous + current;
        previous = current;
        current = next;
    }
    previous - (exponent % 2)
}
