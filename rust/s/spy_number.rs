/// Return whether a positive integer's decimal digit sum equals its product.
#[no_mangle]
pub extern "C" fn spy_number(mut input: i64) -> i64 {
    if input <= 0 { return 0; }
    let mut digit_sum = 0i64;
    let mut digit_product = 1i64;
    while input > 0 {
        let digit = input % 10;
        digit_sum += digit;
        digit_product *= digit;
        input /= 10;
    }
    i64::from(digit_sum == digit_product)
}
