/// Iterative Fibonacci for the shared signed 64-bit benchmark contract.
#[no_mangle]
pub extern "C" fn fibonacci(n: i64) -> i64 {
    if !(0..=92).contains(&n) {
        return -1;
    }
    if n == 0 {
        return 0;
    }

    let mut previous = 0i64;
    let mut current = 1i64;
    let mut index = 1i64;
    while index < n {
        let next = previous + current;
        previous = current;
        current = next;
        index += 1;
    }
    current
}
