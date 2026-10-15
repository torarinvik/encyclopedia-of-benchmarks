/// Check whether n cubed ends with the decimal digits of n.
#[no_mangle]
pub extern "C" fn trimorphic_number(number: i64) -> i64 {
    if !(0..=2_000_000).contains(&number) { return -1; }
    let mut modulus = 10_i64;
    let mut digits = number;
    while digits >= 10 { digits /= 10; modulus *= 10; }
    let cube = number * number * number;
    if cube % modulus == number { 1 } else { 0 }
}
