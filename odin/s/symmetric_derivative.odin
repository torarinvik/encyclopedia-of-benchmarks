package symmetric_derivative

import "core:c"
import "core:math"

MIN_X_NANOUNITS :: i64(-6300000000)
MAX_X_NANOUNITS :: i64(6300000000)
DEFAULT_STEP :: f64(1.0e-10)
INVALID_RESULT :: f64(-1.0e300)

@(export)
symmetric_derivative :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 2 do return INVALID_RESULT
    function_id, x_nanounits := values[0], values[1]
    if (function_id != 0 && function_id != 1) ||
        x_nanounits < MIN_X_NANOUNITS || x_nanounits > MAX_X_NANOUNITS do return INVALID_RESULT

    x := f64(x_nanounits) / 1000000000.0
    upper := if function_id == 0 do math.sin(x + DEFAULT_STEP) else math.exp_f64(x + DEFAULT_STEP)
    lower := if function_id == 0 do math.sin(x - DEFAULT_STEP) else math.exp_f64(x - DEFAULT_STEP)
    return (upper - lower) / (2.0 * DEFAULT_STEP)
}
