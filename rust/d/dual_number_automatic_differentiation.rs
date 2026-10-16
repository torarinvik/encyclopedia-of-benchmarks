/// Nth derivative of x^power via truncated dual-number coefficients.
const MAX_POWER: usize = 8;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn dual_number_automatic_differentiation(position: f64, power: f64, order: f64) -> f64 {
    if !(position >= -1.0 && position <= 1.0) || !(power >= 0.0 && power <= MAX_POWER as f64) ||
        !(order >= 0.0 && order <= MAX_POWER as f64) { return INVALID_RESULT; }
    let exponent = power as usize;
    let derivative_order = order as usize;
    if power != exponent as f64 || order != derivative_order as f64 || derivative_order > exponent {
        return INVALID_RESULT;
    }

    let mut coefficients = [0.0f64; MAX_POWER + 1];
    coefficients[0] = 1.0;
    for step in 0..exponent {
        let mut next = [0.0f64; MAX_POWER + 1];
        next[0] = coefficients[0] * position;
        for degree in 1..=step + 1 {
            next[degree] = coefficients[degree] * position + coefficients[degree - 1];
        }
        coefficients = next;
    }
    let mut result = coefficients[derivative_order];
    for factor in 2..=derivative_order { result *= factor as f64; }
    result
}
