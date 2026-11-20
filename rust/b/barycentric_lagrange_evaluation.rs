const MODULUS: i64 = 998_244_353;
const MAX_NODES: usize = 8;
const MAX_INPUT_LENGTH: usize = 19;

fn mod_pow(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn barycentric_lagrange_evaluation(
    input: *const i64, length: usize,
) -> i64 {
    if input.is_null() || !(4..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let count_value = values[0];
    if !(1..=MAX_NODES as i64).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != 2 * count + 2 { return -1; }
    if values[1..].iter().any(|&value| !(0..MODULUS).contains(&value)) { return -1; }
    for left in 0..count {
        for right in 0..left {
            if values[1 + left] == values[1 + right] { return -1; }
        }
    }

    let mut weights = [0i64; MAX_NODES];
    for index in 0..count {
        let node = values[1 + index];
        let mut product = 1i64;
        for other in 0..count {
            if other == index { continue; }
            let difference = (node - values[1 + other] + MODULUS) % MODULUS;
            product = product * difference % MODULUS;
        }
        weights[index] = mod_pow(product, MODULUS - 2);
    }

    let ordinate_start = 1 + count;
    let query = values[2 * count + 1];
    for index in 0..count {
        if query == values[1 + index] { return values[ordinate_start + index]; }
    }
    let mut numerator = 0i64;
    let mut denominator = 0i64;
    for index in 0..count {
        let difference = (query - values[1 + index] + MODULUS) % MODULUS;
        let term = weights[index] * mod_pow(difference, MODULUS - 2) % MODULUS;
        numerator = (numerator + term * values[ordinate_start + index]) % MODULUS;
        denominator = (denominator + term) % MODULUS;
    }
    if denominator == 0 { return -1; }
    numerator * mod_pow(denominator, MODULUS - 2) % MODULUS
}
