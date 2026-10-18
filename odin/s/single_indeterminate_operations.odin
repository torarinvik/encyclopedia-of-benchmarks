package single_indeterminate_operations

import "core:c"
import "core:math"

MAX_PARSEABLE_INPUT_LENGTH :: 22
MAX_DEGREE :: 8
MAX_OUTPUT_ELEMENTS :: 17

finite :: proc(value: f64) -> bool { return !math.is_nan(value) && !math.is_inf(value) }

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if !finite(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

@(export)
single_indeterminate_operations :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	input_count := int(input_length)
	for index := 0; index < input_count; index += 1 { if !finite(input[index]) do return -1 }
	if !exact_integer(input[0], 0, 5) do return -1
	operation := int(input[0])
	cursor := 1
	if !exact_integer(input[cursor], 0, MAX_DEGREE) do return -1
	degree_a := int(input[cursor])
	cursor += 1
	coefficients_a: [MAX_DEGREE + 1]f64
	if cursor + degree_a + 1 > input_count do return -1
	for index := 0; index <= degree_a; index += 1 {
		value := input[cursor + index]
		if value < -10 || value > 10 do return -1
		coefficients_a[index] = value
	}
	cursor += degree_a + 1

	degree_b := 0
	coefficients_b: [MAX_DEGREE + 1]f64
	parameter := 0.0
	if operation <= 2 {
		if cursor >= input_count || !exact_integer(input[cursor], 0, MAX_DEGREE) do return -1
		degree_b = int(input[cursor])
		cursor += 1
		if cursor + degree_b + 1 > input_count do return -1
		for index := 0; index <= degree_b; index += 1 {
			value := input[cursor + index]
			if value < -10 || value > 10 do return -1
			coefficients_b[index] = value
		}
		cursor += degree_b + 1
		if cursor != input_count do return -1
	} else if operation == 3 || operation == 5 {
		if cursor + 1 != input_count do return -1
		parameter = input[cursor]
		if operation == 3 {
			if parameter < -2 || parameter > 2 do return -1
		} else if parameter < -10 || parameter > 10 do return -1
		cursor += 1
	} else if cursor != input_count do return -1

	staged: [MAX_OUTPUT_ELEMENTS]f64
	result_length := 0
	switch operation {
	case 0:
		result_length = max(degree_a, degree_b) + 1
		if degree_a > degree_b {
			for index := 0; index <= degree_a; index += 1 { staged[index] = coefficients_a[index] }
			for index := 0; index <= degree_b; index += 1 { staged[index] += coefficients_b[index] }
		} else {
			for index := 0; index <= degree_b; index += 1 { staged[index] = coefficients_b[index] }
			for index := 0; index <= degree_a; index += 1 { staged[index] += coefficients_a[index] }
		}
	case 1:
		negated_b: [MAX_DEGREE + 1]f64
		for index := 0; index <= degree_b; index += 1 { negated_b[index] = coefficients_b[index] * -1.0 }
		result_length = max(degree_a, degree_b) + 1
		if degree_a > degree_b {
			for index := 0; index <= degree_a; index += 1 { staged[index] = coefficients_a[index] }
			for index := 0; index <= degree_b; index += 1 { staged[index] += negated_b[index] }
		} else {
			for index := 0; index <= degree_b; index += 1 { staged[index] = negated_b[index] }
			for index := 0; index <= degree_a; index += 1 { staged[index] += coefficients_a[index] }
		}
	case 2:
		result_length = degree_a + degree_b + 1
		for left := 0; left <= degree_a; left += 1 {
			for right := 0; right <= degree_b; right += 1 {
				staged[left + right] += coefficients_a[left] * coefficients_b[right]
			}
		}
	case 3:
		result_length = 1
		for index := 0; index <= degree_a; index += 1 {
			staged[0] += coefficients_a[index] * math.pow_f64(parameter, f64(index))
		}
	case 4:
		result_length = degree_a
		for index := 0; index < degree_a; index += 1 { staged[index] = coefficients_a[index + 1] * f64(index + 1) }
	case:
		result_length = degree_a + 2
		staged[0] = parameter
		for index := 0; index <= degree_a; index += 1 { staged[index + 1] = coefficients_a[index] / f64(index + 1) }
	}
	for index := 0; index < result_length; index += 1 { if !finite(staged[index]) do return -1 }
	if output == nil || capacity < c.size_t(result_length) do return -2
	for index := 0; index < result_length; index += 1 { output[index] = staged[index] }
	return i64(result_length)
}
