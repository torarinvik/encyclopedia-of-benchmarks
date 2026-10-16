const MIN_VALUE: f64 = 1e-6;
const MAX_VALUE: f64 = 1e6;

#[no_mangle]
pub extern "C" fn fast_inverse_sqrt_cpp(value: f64) -> f64 {
    if !value.is_finite() || value < MIN_VALUE || value > MAX_VALUE {
        return -1.0;
    }
    let mut y = value;
    let x2 = y * 0.5;
    let bits = y.to_bits() as i64;
    let seed_bits = 0x5fe6eb50c7b537a9_i64 - (bits >> 1);
    y = f64::from_bits(seed_bits as u64);
    y = y * (1.5 - (x2 * y * y));
    y = y * (1.5 - (x2 * y * y));
    y
}
