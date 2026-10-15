package average_absolute_deviation_rounded
import "core:c"
import "core:math"
MAX_LENGTH :: 256
MIN_VALUE :: i64(-2_147_483_648)
MAX_VALUE :: i64(2_147_483_647)
INVALID_RESULT :: f64 = -1.0e300

round_ties_even :: proc(value: f64) -> f64 {
	lower := math.floor(value)
	fraction := value - lower
	if fraction < 0.5 do return lower
	if fraction > 0.5 do return lower + 1.0
	if i64(lower) % 2 == 0 do return lower
	return lower + 1.0
}

@(export)
average_absolute_deviation_rounded :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
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
        deviations += (if value >= average { value - average } else { average - value })
    }
    return round_ties_even((deviations / f64(length)) * 100.0) / 100.0
}
