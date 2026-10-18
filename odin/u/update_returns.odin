package update_returns

import "core:c"
import "core:math"

MIN_RETURNS :: 2
MAX_RETURNS :: 60
MAX_INPUT_LENGTH :: c.size_t(62)
MAX_OUTPUT_LENGTH :: 63
Z_95 :: 1.6448536269514722

@(export)
update_returns :: proc "c" (input: [^]f64, input_length: c.size_t,
		output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < c.size_t(1 + MIN_RETURNS) || input_length > MAX_INPUT_LENGTH do return -1
	for index := c.size_t(0); index < input_length; index += 1 {
		if !math.is_finite(input[index]) do return -1
	}

	raw_count := input[0]
	if raw_count < f64(MIN_RETURNS) || raw_count > f64(MAX_RETURNS) || math.trunc(raw_count) != raw_count do return -1
	count := int(raw_count)
	if input_length != c.size_t(1 + count) do return -1

	var staged: [MAX_OUTPUT_LENGTH]f64
	sum := 0.0
	for index := 0; index < count; index += 1 {
		value := input[index + 1]
		if value < -0.25 || value > 0.25 do return -1
		staged[index] = value
		sum += value
	}
	mean := sum / f64(count)
	squared_deviation_sum := 0.0
	for index := 0; index < count; index += 1 {
		deviation := staged[index] - mean
		squared_deviation_sum += deviation * deviation
	}
	volatility := math.sqrt_f64(squared_deviation_sum / f64(count - 1))
	if !math.is_finite(mean) || !math.is_finite(volatility) || volatility == 0.0 do return -1
	parametric_var := 100000.0 * (Z_95 * volatility - mean)
	if !math.is_finite(parametric_var) do return -1

	staged[count] = mean
	staged[count + 1] = volatility
	staged[count + 2] = parametric_var
	result_length := count + 3
	if output == nil || output_capacity < c.size_t(result_length) do return -2
	for index := 0; index < result_length; index += 1 {
		output[index] = staged[index]
	}
	return i64(result_length)
}
