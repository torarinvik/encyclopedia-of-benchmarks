package monte_carlo_expected_shortfall

import "core:c"
import "core:math"

MIN_RETURNS :: 20
MAX_RETURNS :: 64
MIN_SIMULATIONS :: 20
MAX_SIMULATIONS :: 128
MAX_VALID_INPUT_LENGTH :: 197
MAX_PARSEABLE_INPUT_LENGTH :: 198

finite_value :: proc(value: f64) -> bool {
	return !math.is_nan(value) && !math.is_inf(value)
}

@(export)
monte_carlo_expected_shortfall :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 45 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	for index := 0; index < int(input_length); index += 1 {
		if !finite_value(input[index]) do return -1
	}
	portfolio, confidence, horizon := input[0], input[1], input[2]
	simulation_value, return_count_value := input[3], input[4]
	if portfolio < 100.0 || portfolio > 1000000.0 || confidence < 0.5 || confidence > 0.95 ||
		horizon < 1.0 || horizon > 10.0 || simulation_value < f64(MIN_SIMULATIONS) ||
		simulation_value > f64(MAX_SIMULATIONS) || return_count_value < f64(MIN_RETURNS) ||
		return_count_value > f64(MAX_RETURNS) do return -1
	simulation_count, return_count := int(simulation_value), int(return_count_value)
	if f64(simulation_count) != simulation_value || f64(return_count) != return_count_value do return -1
	if int(input_length) != 5 + return_count + simulation_count || int(input_length) > MAX_VALID_INPUT_LENGTH do return -1

	returns: [MAX_RETURNS]f64
	simulated: [MAX_SIMULATIONS]f64
	sum := f64(0.0)
	for index := 0; index < return_count; index += 1 {
		value := input[5+index]
		if value < -0.25 || value > 0.25 do return -1
		returns[index] = value
		sum += value
	}
	for index := 0; index < simulation_count; index += 1 {
		z := input[5+return_count+index]
		if z < -3.0 || z > 3.0 do return -1
		simulated[index] = z
	}
	mean := sum / f64(return_count)
	squared_deviation := f64(0.0)
	for index := 0; index < return_count; index += 1 {
		delta := returns[index] - mean
		squared_deviation += delta * delta
	}
	volatility := math.sqrt(squared_deviation / f64(return_count-1))
	if !finite_value(volatility) || volatility == 0.0 do return -1
	for index := 0; index < simulation_count; index += 1 {
		simulated[index] = mean + volatility * simulated[index]
	}
	for index := 1; index < simulation_count; index += 1 {
		value := simulated[index]
		position := index
		for position > 0 && simulated[position-1] > value {
			simulated[position] = simulated[position-1]
			position -= 1
		}
		simulated[position] = value
	}

	tail_value := math.floor_f64((1.0 - confidence) * f64(simulation_count))
	if tail_value < 1.0 || tail_value > f64(simulation_count) do return -1
	tail_count := int(tail_value)
	tail_sum := f64(0.0)
	for index := 0; index < tail_count; index += 1 {
		tail_sum += simulated[index]
	}
	metric := -(tail_sum / f64(tail_count)) * portfolio * math.sqrt(horizon)
	if !finite_value(metric) do return -1
	if output == nil || output_capacity < 1 do return -2
	output[0] = metric
	return 1
}
