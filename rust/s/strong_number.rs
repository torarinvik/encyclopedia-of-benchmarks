/// Check whether the sum of the decimal digits' factorials equals the input.
#[no_mangle]
pub extern "C" fn strong_number(number: i64) -> i64 {
    if number < i32::MIN as i64 || number > i32::MAX as i64 { return -1; }
    if number < 0 { return 0; }
    let mut remaining = number;
    let mut sum = 0_i64;
    if remaining == 0 { sum = 1; }
    while remaining > 0 {
        let digit = remaining % 10;
        let mut factorial = 1_i64;
        for factor in 2..=digit { factorial *= factor; }
        sum += factorial;
        remaining /= 10;
    }
    if sum == number { 1 } else { 0 }
}
