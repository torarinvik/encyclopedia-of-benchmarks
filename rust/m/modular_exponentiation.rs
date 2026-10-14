/// Binary exponentiation under a positive signed 32-bit modulus.
#[no_mangle]
pub extern "C" fn modular_exponentiation(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (base_input, exponent_input, modulus) = (values[0], values[1], values[2]);
    if !(-2_147_483_648..=2_147_483_647).contains(&base_input) ||
        !(0..=2_147_483_647).contains(&exponent_input) || !(1..=2_147_483_647).contains(&modulus) { return -1; }
    let mut base = base_input % modulus;
    if base < 0 { base += modulus; }
    let mut exponent = exponent_input as u64;
    let mut result = 1 % modulus;
    while exponent != 0 {
        if exponent & 1 != 0 { result = (result * base) % modulus; }
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    result
}
