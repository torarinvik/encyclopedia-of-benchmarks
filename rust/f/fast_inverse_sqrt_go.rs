const MIN_VALUE: f64 = 1e-6;
const MAX_VALUE: f64 = 1e6;

#[inline(never)]
fn newton_step(x2: f32, y: f32) -> f32 {
    let product1: f32 = x2 * y;
    let product2: f32 = product1 * y;
    let correction: f32 = 1.5_f32 - product2;
    y * correction
}

/// Match Go's two binary32 Newton corrections after the magic-number seed.
#[no_mangle]
pub extern "C" fn fast_inverse_sqrt_go(value: f64) -> f64 {
    if !value.is_finite() || value < MIN_VALUE || value > MAX_VALUE {
        return -1.0;
    }
    let number = value as f32;
    let x2 = number * 0.5_f32;
    let bits = 0x5f3759df_u32 - (number.to_bits() >> 1);
    let mut y = f32::from_bits(bits);
    y = newton_step(x2, y);
    y = newton_step(x2, y);
    f64::from(y)
}
