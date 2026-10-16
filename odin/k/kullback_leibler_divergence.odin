package kullback_leibler_divergence

import "core:c"
import "core:math"

MAX_COUNT :: 64
SCALE :: 1_000_000.0
INVALID_RESULT :: -1.0e300

@(export)
kullback_leibler_divergence :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length < 3 || length > 129 do return INVALID_RESULT
    count_value := values[0]
    if count_value < 1 || count_value > MAX_COUNT do return INVALID_RESULT
    count := int(count_value)
    if length != c.size_t(1 + 2 * count) do return INVALID_RESULT

    for i := 0; i < count; i += 1 {
        target := values[1 + i]
        prediction := values[1 + count + i]
        if target < 0 || target > 1_000_000 || prediction < 0 || prediction > 1_000_000 ||
            (target > 0 && prediction == 0) do return INVALID_RESULT
    }
    total := 0.0
    for i := 0; i < count; i += 1 {
        target_scaled := values[1 + i]
        if target_scaled == 0 do continue
        prediction_scaled := values[1 + count + i]
        target := f64(target_scaled) / SCALE
        prediction := f64(prediction_scaled) / SCALE
        total += target * math.log_f64(target / prediction)
    }
    return total
}
