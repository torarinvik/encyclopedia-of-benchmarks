#[no_mangle]
pub extern "C" fn problem137(n: i64) -> i64 {
    if !(1..=23).contains(&n) { return -1; }
    let (mut previous, mut current) = (1i64, 1i64);
    for _ in 0..(2 * n - 1) {
        let next = previous + current;
        previous = current;
        current = next;
    }
    previous * current
}
