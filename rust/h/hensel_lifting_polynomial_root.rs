const MAX_DEGREE: i64 = 4;
const MAX_PRIME: i64 = 43;
const MAX_EXPONENT: i64 = 6;
const MAX_MODULUS: i64 = 100_000;
const MAX_LENGTH: usize = 10;

fn is_prime(value: i64) -> bool {
    if value < 2 { return false; }
    let mut divisor = 2_i64;
    while divisor * divisor <= value {
        if value % divisor == 0 { return false; }
        divisor += 1;
    }
    true
}

fn evaluate(coefficients: &[i64], x: i64, modulus: i64) -> i64 {
    let mut value = 0_i64;
    for &coefficient in coefficients.iter().rev() {
        value = (value * x + coefficient).rem_euclid(modulus);
    }
    value
}

fn derivative(coefficients: &[i64], x: i64, prime: i64) -> i64 {
    let degree = coefficients.len() - 1;
    let mut value = 0_i64;
    for index in (1..=degree).rev() {
        value = (value * x + index as i64 * coefficients[index]).rem_euclid(prime);
    }
    value
}

fn implementation(words: &[i64]) -> i64 {
    if words.len() < 6 || words.len() > MAX_LENGTH { return -1; }
    let degree_value = words[0];
    let prime = words[1];
    let exponent = words[2];
    let seed = words[3];
    if !(1..=MAX_DEGREE).contains(&degree_value) || !(2..=MAX_PRIME).contains(&prime) { return -1; }
    if !(1..=MAX_EXPONENT).contains(&exponent) || seed < 0 || seed >= prime { return -1; }
    let degree = degree_value as usize;
    if words.len() != degree + 5 || !is_prime(prime) { return -1; }
    let coefficients = &words[4..];
    if coefficients.iter().any(|&c| !(-1000..=1000).contains(&c)) { return -1; }

    let mut modulus = 1_i64;
    for _ in 0..exponent {
        if modulus > MAX_MODULUS / prime { return -1; }
        modulus *= prime;
    }
    if evaluate(coefficients, seed, prime) != 0 { return -1; }
    let derivative_value = derivative(coefficients, seed, prime);
    if derivative_value == 0 { return -1; }
    let mut inverse = 0_i64;
    for candidate in 1..prime {
        if derivative_value * candidate % prime == 1 {
            inverse = candidate;
            break;
        }
    }
    if inverse == 0 { return -1; }

    let mut root = seed;
    let mut power = prime;
    for _ in 1..exponent {
        let next_power = power * prime;
        let quotient_digit = evaluate(coefficients, root, next_power) / power;
        let correction = (-quotient_digit * inverse).rem_euclid(prime);
        root += correction * power;
        power = next_power;
    }
    root
}

#[no_mangle]
pub unsafe extern "C" fn hensel_lifting_polynomial_root(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(6..=MAX_LENGTH).contains(&length) { return -1; }
    implementation(std::slice::from_raw_parts(input, length))
}
