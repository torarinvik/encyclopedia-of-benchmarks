/// Sum even Fibonacci terms strictly below the input limit.
#[no_mangle]
pub extern "C" fn problem2(limit: i64) -> i64 {
    if !(0..=4_000_000).contains(&limit) {
        return -1;
    }
    let (mut previous, mut current) = (1i64, 2i64);
    let mut sum = 0i64;
    while current < limit {
        if current % 2 == 0 {
            sum += current;
        }
        let next = previous + current;
        previous = current;
        current = next;
    }
    sum
}
