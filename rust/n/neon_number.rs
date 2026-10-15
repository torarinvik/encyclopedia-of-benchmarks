/// A neon number equals the sum of the digits of its square.
#[no_mangle]
pub extern "C" fn neon_number(number: i64) -> i64 {
    if number < 0 { return 0; }
    if number > 3_000_000_000 { return -1; }
    let mut square = number * number;
    let mut digit_sum = 0_i64;
    while square > 0 {
        digit_sum += square % 10;
        square /= 10;
    }
    if digit_sum == number { 1 } else { 0 }
}
