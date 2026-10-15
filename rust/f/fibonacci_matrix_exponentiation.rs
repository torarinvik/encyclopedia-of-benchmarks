const MAX_INDEX: f64 = 9_007_199_254_740_991.0;
const MAX_MODULUS: f64 = 4_294_967_295.0;

fn multiply_sum(a: u64, b: u64, c: u64, d: u64, modulus: u64) -> u64 {
    ((a * b) % modulus + (c * d) % modulus) % modulus
}

#[no_mangle]
pub extern "C" fn fibonacci_matrix_exponentiation(index_input: f64, modulus_input: f64) -> f64 {
    if !(index_input >= 1.0 && index_input <= MAX_INDEX) ||
        !(modulus_input >= 1.0 && modulus_input <= MAX_MODULUS) { return -1.0; }
    let index = index_input as u64;
    let modulus = modulus_input as u64;
    if index as f64 != index_input || modulus as f64 != modulus_input { return -1.0; }

    let mut r00 = 1 % modulus;
    let mut r01 = 0;
    let mut r10 = 0;
    let mut r11 = 1 % modulus;
    let mut t00 = 0;
    let mut t01 = 1 % modulus;
    let mut t10 = 1 % modulus;
    let mut t11 = 1 % modulus;
    let mut exponent = index - 1;
    while exponent > 0 {
        if exponent % 2 == 1 {
            let n00 = multiply_sum(r00, t00, r01, t10, modulus);
            let n01 = multiply_sum(r00, t01, r01, t11, modulus);
            let n10 = multiply_sum(r10, t00, r11, t10, modulus);
            let n11 = multiply_sum(r10, t01, r11, t11, modulus);
            r00 = n00; r01 = n01; r10 = n10; r11 = n11;
            exponent -= 1;
        } else {
            let n00 = multiply_sum(t00, t00, t01, t10, modulus);
            let n01 = multiply_sum(t00, t01, t01, t11, modulus);
            let n10 = multiply_sum(t10, t00, t11, t10, modulus);
            let n11 = multiply_sum(t10, t01, t11, t11, modulus);
            t00 = n00; t01 = n01; t10 = n10; t11 = n11;
            exponent /= 2;
        }
    }
    ((r00 + r10) % modulus) as f64
}
