/// Count transitions in the classic Collatz sequence for a bounded input.
#[no_mangle]
pub extern "C" fn collatz(n: i64) -> i64 {
    if !(1..=1_000_000).contains(&n) { return -1; }
    let mut current = n;
    let mut steps = 0;
    while current != 1 {
        current = if current % 2 == 0 { current / 2 } else { 3 * current + 1 };
        steps += 1;
    }
    steps
}
