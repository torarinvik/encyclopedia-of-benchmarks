const MIN_VALUE: f64 = 1e-6;
const MAX_VALUE: f64 = 1e6;

/// Match PHP's float32 pack/unpack through binary32 bit reinterpretation.
#[no_mangle]
pub extern "C" fn fast_inverse_square_root(value: f64) -> f64 {
    if !value.is_finite() || value < MIN_VALUE || value > MAX_VALUE {
        return -1.0;
    }
    let seed_input = value as f32;
    let bits = seed_input.to_bits() as i32;
    let seed_bits = 0x5f3759df_i32 - (bits >> 1);
    let seed = f32::from_bits(seed_bits as u32);
    let y = f64::from(seed);
    y * (1.5 - 0.5 * value * y * y)
}
