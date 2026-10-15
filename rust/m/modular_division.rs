/// Fermat modular division for a bounded prime modulus.
fn is_prime(value: i64) -> bool {
    if value < 2 { return false; }
    let mut divisor = 2i64;
    while divisor <= value / divisor {
        if value % divisor == 0 { return false; }
        divisor += 1;
    }
    true
}

fn modular_power(base_input: i64, exponent_input: u64, modulus: i64) -> i64 {
    let mut base = base_input % modulus;
    let mut exponent = exponent_input;
    let mut result = 1i64;
    while exponent != 0 {
        if exponent & 1 != 0 { result = (result * base) % modulus; }
        exponent >>= 1;
        base = (base * base) % modulus;
    }
    result
}

#[no_mangle]
pub extern "C" fn modular_division(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (numerator, denominator, modulus) = (values[0], values[1], values[2]);
    if numerator < 0 || numerator > 1_000_000_000_000 || denominator < 0 || denominator > 1_000_000_000_000 ||
        modulus < 2 || modulus > 1_000_000 || !is_prime(modulus) || denominator % modulus == 0 {
        return -1;
    }
    let inverse = modular_power(denominator, (modulus - 2) as u64, modulus);
    ((numerator % modulus) * inverse) % modulus
}
