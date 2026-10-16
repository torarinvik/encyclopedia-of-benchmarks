package smooth_l1_loss

import "core:c"

MAX_COUNT :: i64(256)
MAX_PARSED_COUNT :: i64(257)
MAX_SAMPLE :: i64(1_000_000)
MAX_INPUT_LENGTH :: c.size_t(515)
INVALID_RESULT :: f64(-1.0e300)

@(export)
smooth_l1_loss :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length < 1 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
    count_value := values[0]
    if count_value < 0 || count_value > MAX_PARSED_COUNT do return INVALID_RESULT
    if length != c.size_t(1 + 2 * count_value) ||
        count_value == 0 || count_value > MAX_COUNT do return INVALID_RESULT
    count := int(count_value)
    for index := 0; index < count * 2; index += 1 {
        if values[1 + index] < -MAX_SAMPLE || values[1 + index] > MAX_SAMPLE do return INVALID_RESULT
    }
    total := f64(0.0)
    for index := 0; index < count; index += 1 {
        difference := f64(values[1 + index]) / 1_000_000.0 -
                      f64(values[1 + count + index]) / 1_000_000.0
        residual := difference
        if residual < 0.0 do residual = -residual
        if residual < 1.0 { total += 0.5 * residual * residual / 1.0 } else { total += residual - 0.5 }
    }
    return total / f64(count)
}
