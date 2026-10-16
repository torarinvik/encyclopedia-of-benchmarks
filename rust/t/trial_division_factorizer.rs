#[no_mangle]
pub extern "C" fn trial_division_factorizer(input: i64) -> i64 {
    if input < i32::MIN as i64 || input > i32::MAX as i64 || input == 0 || input == i32::MIN as i64 {
        return -1;
    }
    let number = input.abs();
    let mut divisor = 2_i64;
    while divisor <= number / divisor {
        if number % divisor == 0 { return divisor; }
        divisor += 1;
    }
    0
}
