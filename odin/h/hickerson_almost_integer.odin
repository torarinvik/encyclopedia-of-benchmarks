package hickerson_almost_integer

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300

@(export)
hickerson_almost_integer :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 1 do return INVALID_RESULT
    n := values[0]
    if n < 1 || n > 17 do return INVALID_RESULT
    log_two := math.log_f64(2.0)
    value := 1.0 / (2.0 * log_two * log_two)
    for index := i64(2); index <= n; index += 1 {
        value = (f64(index) / log_two) * value
    }
    return value
}
