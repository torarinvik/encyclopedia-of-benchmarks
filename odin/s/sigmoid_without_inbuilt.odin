package sigmoid_without_inbuilt

import "core:math"

INVALID_RESULT :: -1.0e300

@(export)
sigmoid_without_inbuilt :: proc "c" (x, slope: f64) -> f64 {
    if math.is_nan_f64(x) || math.is_nan_f64(slope) || x < -10.0 || x > 10.0 ||
        slope < -10.0 || slope > 10.0 do return INVALID_RESULT
    return 1.0 / (1.0 + math.exp_f64(-slope * x))
}

