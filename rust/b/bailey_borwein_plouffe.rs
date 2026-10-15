/// Return the source's extracted hexadecimal digit as a numeric nibble.
fn modular_power_16(mut exponent: i64, modulus: i64) -> i64 {
    let mut result = 1i64 % modulus;
    let mut base = 16 % modulus;
    while exponent > 0 {
        if exponent & 1 != 0 { result = (result * base) % modulus; }
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    result
}

fn bbp_subsum(position: i64, addend: i64) -> f64 {
    let mut total = 0.0;
    for index in 0..position + 1000 {
        let denominator = 8 * index + addend;
        let exponent = position - 1 - index;
        let term = if index < position {
            modular_power_16(exponent, denominator) as f64 / denominator as f64
        } else {
            16.0f64.powf(exponent as f64) / denominator as f64
        };
        total += term;
    }
    total
}

#[no_mangle]
pub extern "C" fn bailey_borwein_plouffe(position: i64) -> i64 {
    if !(1..=10).contains(&position) { return -1; }
    let sum_result = 4.0 * bbp_subsum(position, 1) - 2.0 * bbp_subsum(position, 4)
        - bbp_subsum(position, 5) - bbp_subsum(position, 6);
    let fractional = sum_result - sum_result.floor();
    (fractional * 16.0) as i64
}
