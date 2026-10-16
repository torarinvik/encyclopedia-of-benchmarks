module symmetric_derivative

import math

const min_x_nanounits = i64(-6300000000)
const max_x_nanounits = i64(6300000000)
const default_step = 1.0e-10
const invalid_result = -1.0e300

@[export: 'symmetric_derivative']
pub fn symmetric_derivative(values &i64, length usize) f64 {
    unsafe {
        if values == nil || length != 2 {
            return invalid_result
        }
        function_id, x_nanounits := values[0], values[1]
        if (function_id != 0 && function_id != 1) ||
            x_nanounits < min_x_nanounits || x_nanounits > max_x_nanounits {
            return invalid_result
        }

        x := f64(x_nanounits) / 1000000000.0
        upper := if function_id == 0 { math.sin(x + default_step) } else { math.exp(x + default_step) }
        lower := if function_id == 0 { math.sin(x - default_step) } else { math.exp(x - default_step) }
        return (upper - lower) / (2.0 * default_step)
    }
}
