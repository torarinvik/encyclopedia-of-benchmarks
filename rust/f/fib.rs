#[no_mangle]
pub extern "C" fn fib(n: i64) -> i64 {
    if !(0..=90).contains(&n) { return -1; }
    let (mut previous, mut current) = (1i64, 2i64);
    for _ in 0..n { let next = previous + current; previous = current; current = next; }
    previous
}
