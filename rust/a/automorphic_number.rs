/// Check whether the square ends with the original nonnegative integer.
fn add_mod(left: u64, right: u64, modulus: u64) -> u64 {
    if left >= modulus - right { left - (modulus - right) } else { left + right }
}

fn multiply_mod(mut left: u64, mut right: u64, modulus: u64) -> u64 {
    let mut result = 0;
    while right != 0 {
        if right & 1 != 0 { result = add_mod(result, left, modulus); }
        right >>= 1;
        if right != 0 { left = add_mod(left, left, modulus); }
    }
    result
}

#[no_mangle]
pub extern "C" fn automorphic_number(n: i64) -> i64 {
    if n < 0 { return 0; }
    let number = n as u64;
    let mut modulus = 10_u64;
    let mut digits = number;
    while digits >= 10 {
        digits /= 10;
        modulus *= 10;
    }
    i64::from(multiply_mod(number, number, modulus) == number)
}
