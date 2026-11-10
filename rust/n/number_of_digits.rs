/// Count base-10 digits in the magnitude of a signed 64-bit value.
#[no_mangle]
pub extern "C" fn number_of_digits(value: i64) -> i64 {
    let mut magnitude = value.unsigned_abs();
    if magnitude < 10 {
        return 1;
    }
    let mut digits = 1;
    while magnitude >= 10000 {
        magnitude /= 10000;
        digits += 4;
    }
    if magnitude < 10 {
        return digits;
    }
    if magnitude < 100 {
        return digits + 1;
    }
    digits + if magnitude < 1000 { 2 } else { 3 }
}
