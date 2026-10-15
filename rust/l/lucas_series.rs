#[no_mangle]
pub extern "C" fn lucas_series(n: i64) -> i64 {
    if !(0..=90).contains(&n) { return -1; }
    if n == 0 { return 2; }
    let (mut previous, mut current) = (2i64, 1i64);
    for _ in 2..=n { let next = previous + current; previous = current; current = next; }
    current
}
