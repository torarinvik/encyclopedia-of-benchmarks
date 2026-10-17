package sharpe_ratio

import "core:c"
import "core:math"

MAX_PARSEABLE_LENGTH :: 67
MAX_SAMPLE_COUNT :: i64(64)
SCALE :: 1_000_000.0
MIN_RETURN_MICRO :: i64(-200_000)
MAX_RETURN_MICRO :: i64(200_000)
MIN_RISK_FREE_MICRO :: i64(-100_000)
MAX_RISK_FREE_MICRO :: i64(100_000)
INVALID_RESULT :: f64 = -1.0e300

@(export)
sharpe_ratio :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 2 || length > MAX_PARSEABLE_LENGTH do return INVALID_RESULT
	count_value := values[0]
	if count_value < 2 || count_value > MAX_SAMPLE_COUNT || length != c.size_t(count_value + 2) do return INVALID_RESULT
	count := c.size_t(count_value)
	risk_free_micro := values[count+1]
	if risk_free_micro < MIN_RISK_FREE_MICRO || risk_free_micro > MAX_RISK_FREE_MICRO do return INVALID_RESULT

	sum := f64(0.0)
	constant_returns := true
	for index := c.size_t(0); index < count; index += 1 {
		return_micro := values[index+1]
		if return_micro < MIN_RETURN_MICRO || return_micro > MAX_RETURN_MICRO do return INVALID_RESULT
		if return_micro != values[1] do constant_returns = false
		sum += f64(return_micro) / SCALE
	}
	if constant_returns do return INVALID_RESULT

	mean := sum / f64(count)
	risk_free_rate := f64(risk_free_micro) / SCALE
	excess_return := mean - risk_free_rate
	squared_deviations := f64(0.0)
	for index := c.size_t(0); index < count; index += 1 {
		return_value := f64(values[index+1]) / SCALE
		difference := return_value - mean
		squared_deviations += math.pow(difference, 2.0)
	}
	variance := squared_deviations / f64(count-1)
	standard_deviation := math.sqrt(variance)
	if standard_deviation == 0.0 do return INVALID_RESULT
	return excess_return / standard_deviation
}
