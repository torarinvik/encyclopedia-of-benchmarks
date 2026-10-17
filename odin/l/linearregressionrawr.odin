package linearregressionrawr

import "core:c"
import "core:math"

MIN_SAMPLE_COUNT :: 2
MAX_SAMPLE_COUNT :: 32
MAX_INPUT_LENGTH :: c.size_t(66)

@(export)
linearregressionrawr :: proc "c" (input: [^]f64, input_length: c.size_t,
		output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	n_value := input[0]
	if n_value != n_value || n_value < f64(MIN_SAMPLE_COUNT) || n_value > f64(MAX_SAMPLE_COUNT) ||
		math.floor_f64(n_value) != n_value do return -1
	n := int(n_value)
	if input_length != c.size_t(1 + 2 * n) do return -1

	predictors: [MAX_SAMPLE_COUNT]i64
	responses: [MAX_SAMPLE_COUNT]i64
	predictor_sum: i64 = 0
	response_sum: i64 = 0
	cross_sum: i64 = 0
	square_sum: i64 = 0
	for index := 0; index < n; index += 1 {
		value := input[1 + index]
		if value != value || value < -4.0 || value > 4.0 || math.floor_f64(value) != value do return -1
		predictors[index] = i64(value)
		predictor_sum += predictors[index]
	}
	for index := 0; index < n; index += 1 {
		value := input[1 + n + index]
		if value != value || value < -16.0 || value > 16.0 || math.floor_f64(value) != value do return -1
		responses[index] = i64(value)
		response_sum += responses[index]
		cross_sum += predictors[index] * responses[index]
		square_sum += predictors[index] * predictors[index]
	}
	if predictor_sum != 0 do return -1
	all_equal := true
	for index := 1; index < n; index += 1 {
		if predictors[index] != predictors[0] do all_equal = false
	}
	if all_equal do return -1

	if output == nil || output_capacity < 2 do return -2
	output[0] = f64(response_sum) / f64(n)
	output[1] = f64(cross_sum) / f64(square_sum)
	return 2
}
