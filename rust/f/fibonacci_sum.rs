/// Inclusive Fibonacci range sum for the shared unsigned pair ABI.
#[no_mangle]
pub extern "C" fn fibonacci_sum(start: u64, end: u64) -> i64 {
    if end > 90 || start > end {
        return -1;
    }
    let lower_index = start + 1;
    let upper_index = end + 2;
    let mut previous = 0i64;
    let mut current = 1i64;
    let mut lower = 0i64;
    let mut lower_current = 1i64;
    let mut i = 1u64;
    while i < upper_index {
        let next = previous + current;
        previous = current;
        current = next;
        if i < lower_index {
            let lower_next = lower + lower_current;
            lower = lower_current;
            lower_current = lower_next;
        }
        i += 1;
    }
    current - lower_current
}
