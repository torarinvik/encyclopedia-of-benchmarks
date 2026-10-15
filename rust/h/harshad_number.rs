/// Return 1 when n is divisible by its base-10 digit sum, else 0.
#[no_mangle]
pub extern "C" fn harshad_number(n: i64) -> i64 {
    if n <= 0 || n > i32::MAX as i64 {
        return -1;
    }
    let mut remaining = n;
    let mut digit_sum = 0_i64;
    while remaining > 0 {
        digit_sum += remaining % 10;
        remaining /= 10;
    }
    if n % digit_sum == 0 { 1 } else { 0 }
}
