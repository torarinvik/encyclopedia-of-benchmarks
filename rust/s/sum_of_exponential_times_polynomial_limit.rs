/// Infinite geometric-weighted power sum via an Eulerian polynomial row.
const MODULUS: i64 = 998_244_353;
const MAX_DEGREE: usize = 256;

fn seppl_mod_pow(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if (exponent & 1) == 1 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub extern "C" fn sum_of_exponential_times_polynomial_limit(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let r = values[0];
    let degree_value = values[1];
    if r < 0 || r >= MODULUS || r == 1 || degree_value < 0 || degree_value > MAX_DEGREE as i64 { return -1; }
    let degree = degree_value as usize;
    let denominator = (1 - r + MODULUS) % MODULUS;
    let inverse = seppl_mod_pow(denominator, MODULUS - 2);
    if degree == 0 { return inverse; }

    let mut row = [0_i64; MAX_DEGREE + 1];
    let mut next_row = [0_i64; MAX_DEGREE + 1];
    row[0] = 1;
    for n in 1..=degree {
        for k in 0..=n {
            let mut value = 0_i64;
            if k > 0 { value += (n - k) as i64 * row[k - 1]; }
            if k < n { value += (k + 1) as i64 * row[k]; }
            next_row[k] = value % MODULUS;
        }
        for k in 0..=n {
            row[k] = next_row[k];
            next_row[k] = 0;
        }
    }

    let mut eulerian_value = 0_i64;
    for k in (1..=degree).rev() {
        eulerian_value = (eulerian_value * r + row[k - 1]) % MODULUS;
    }
    let denominator_power = seppl_mod_pow(inverse, degree as i64 + 1);
    r * eulerian_value % MODULUS * denominator_power % MODULUS
}
