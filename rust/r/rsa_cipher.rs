/// Encrypt one bounded ASCII character using the pinned RSA square-and-multiply operation.
#[no_mangle]
pub unsafe extern "C" fn rsa_cipher_encrypt_ascii(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 3 { return -1; }
    let (ascii_code, exponent_input, modulus) = unsafe {
        (*values, *values.add(1), *values.add(2))
    };
    if !(0..=127).contains(&ascii_code) || !(128..=65_535).contains(&modulus) ||
        exponent_input < 1 || exponent_input >= modulus { return -1; }

    let mut base = ascii_code as u64;
    let mut exponent = exponent_input as u64;
    let modulus = modulus as u64;
    let mut result = 1_u64;
    base %= modulus;
    while exponent > 0 {
        if exponent % 2 == 1 {
            result = ((result as u128 * base as u128) % modulus as u128) as u64;
        }
        exponent >>= 1;
        base = ((base as u128 * base as u128) % modulus as u128) as u64;
    }
    result as i64
}
