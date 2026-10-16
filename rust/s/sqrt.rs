const MIN_VALUE: f64 = 1e-6;
const MAX_VALUE: f64 = 1e6;

#[inline(never)]
fn newton_step(x2: f32, y: f32) -> f32 {
    let product1: f32 = x2 * y;
    let product2: f32 = product1 * y;
    let correction: f32 = 1.5_f32 - product2;
    y * correction
}

/// Reciprocal of the pinned Go binary32 fast-inverse-square-root result.
#[no_mangle]
pub extern "C" fn go_sqrt_f32(value: f64) -> f64 {
    if !value.is_finite() || value < MIN_VALUE || value > MAX_VALUE {
        return -1.0;
    }
    let number = value as f32;
    let x2 = number * 0.5_f32;
    let bits = 0x5f3759df_u32 - (number.to_bits() >> 1);
    let mut inverse_root = f32::from_bits(bits);
    inverse_root = newton_step(x2, inverse_root);
    inverse_root = newton_step(x2, inverse_root);
    f64::from(1.0_f32 / inverse_root)
}
