package average_absolute_deviation
import "core:c"
MAX_LENGTH :: 256
MIN_VALUE :: i64(-2_147_483_648)
MAX_VALUE :: i64(2_147_483_647)
INVALID_RESULT :: f64(-1.0e300)
@(export)
average_absolute_deviation :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length == 0 || length > MAX_LENGTH do return INVALID_RESULT
    sum := f64(0.0)
    for index := c.size_t(0); index < length; index += 1 {
        value := values[index]
        if value < MIN_VALUE || value > MAX_VALUE do return INVALID_RESULT
        sum += f64(value)
    }
    average := sum / f64(length)
    deviations := f64(0.0)
    for index := c.size_t(0); index < length; index += 1 {
        value := f64(values[index])
        if value >= average {
            deviations += value - average
        } else {
            deviations += average - value
        }
    }
    return deviations / f64(length)
}
