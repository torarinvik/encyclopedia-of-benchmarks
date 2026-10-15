/// Return the source-compatible derangement count for n in 0..=20.
#[no_mangle]
pub extern "C" fn derangement(n: i64) -> i64 {
    if !(0..=20).contains(&n) {
        return -1;
    }
    if n < 2 {
        return 0;
    }
    if n == 2 {
        return 1;
    }

    let mut previous = 1_i64;
    let mut previous_previous = 0_i64;
    let mut i = 3_i64;
    while i <= n {
        let current = (i - 1) * (previous + previous_previous);
        previous_previous = previous;
        previous = current;
        i += 1;
    }
    previous
}
