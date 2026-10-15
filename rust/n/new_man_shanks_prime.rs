const MAX_INDEX: i64 = 25;
const INT32_MIN_VALUE: i64 = i32::MIN as i64;
const INT32_MAX_VALUE: i64 = i32::MAX as i64;

/// Compare the source recurrence term a[n] with expected; this is not primality testing.
#[no_mangle]
pub extern "C" fn new_man_shanks_prime(n: i64, expected: i64) -> i64 {
    if !(1..=MAX_INDEX).contains(&n) || !(INT32_MIN_VALUE..=INT32_MAX_VALUE).contains(&expected) {
        return -1;
    }
    let mut previous_previous: i32 = 1;
    let mut previous: i32 = 1;
    if n == 1 {
        return if i64::from(previous) == expected { 1 } else { 0 };
    }
    for _index in 2..=n {
        let current = 2 * previous + previous_previous;
        previous_previous = previous;
        previous = current;
    }
    if i64::from(previous) == expected { 1 } else { 0 }
}
