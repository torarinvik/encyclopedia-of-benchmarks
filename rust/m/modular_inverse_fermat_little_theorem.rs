/// Fermat modular inverse via prime validation and binary exponentiation.
fn is_prime(value: i64) -> bool {
    if value <= 1 { return false; }
    let mut divisor = 2_i64;
    while divisor * divisor <= value {
        if value % divisor == 0 { return false; }
        divisor += 1;
    }
    true
}

fn binary_exponentiation(base_input: i64, exponent_input: i64, modulus: i64) -> i64 {
    let mut base = base_input % modulus;
    let mut exponent = exponent_input;
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent % 2 != 0 { result = result * base % modulus; }
        base = base * base % modulus;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub extern "C" fn modular_inverse_fermat_little_theorem(a: i64, m: i64) -> i64 {
    if !(-1_000_000..=1_000_000).contains(&a) || !(2..=1_000_000).contains(&m) {
        return -1;
    }
    if a == 0 || a <= -m || a >= m || !is_prime(m) { return -1; }
    let mut normalized = a;
    while normalized < 0 { normalized += m; }
    binary_exponentiation(normalized, m - 2, m)
}
