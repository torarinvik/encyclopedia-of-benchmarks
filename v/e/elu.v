module elu

import math

const invalid_result = -1.0e300
const alpha_max = 1_000_000.0

@[export: 'elu']
pub fn elu(x f64, alpha f64) f64 {
    if math.is_nan(x) || math.is_nan(alpha) || x < -100.0 || x > 100.0 || alpha < -alpha_max || alpha > alpha_max { return invalid_result }
    if x < 0.0 { return alpha * (math.exp(x) - 1.0) }
    return x
}
