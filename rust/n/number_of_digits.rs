/// Count base-10 digits in the magnitude of a signed 64-bit value.
#[no_mangle]
pub extern "C" fn number_of_digits(value: i64) -> i64 {
    let mut magnitude = value.unsigned_abs();
    let mut digits = 1;
    while magnitude >= 10 { magnitude /= 10; digits += 1; }
    digits
}
