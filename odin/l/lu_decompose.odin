package lu_decompose

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 18

rounded_multiply :: #force_no_inline proc "contextless" (left, right: f64) -> f64 { return left * right }
rounded_add :: #force_no_inline proc "contextless" (left, right: f64) -> f64 { return left + right }
rounded_subtract :: #force_no_inline proc "contextless" (left, right: f64) -> f64 { return left - right }
rounded_divide :: #force_no_inline proc "contextless" (left, right: f64) -> f64 { return left / right }

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

@(export)
lu_decompose :: proc "c" (input: [^]f64, input_length: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 1, 4) do return -1
	n := int(input[0])
	if int(input_length) != 1+n*n do return -1
	matrix: [16]f64
	for i := 0; i < n*n; i += 1 {
		if !exact_integer(input[i+1], -8, 8) do return -1
		matrix[i] = input[i+1]
	}
	lower, upper: [16]f64
	for row := 0; row < n; row += 1 {
		for column := row; column < n; column += 1 {
			sum := f64(0)
			for index := 0; index < row; index += 1 {
				product := rounded_multiply(lower[row*n+index], upper[index*n+column])
				sum = rounded_add(sum, product)
			}
			upper[row*n+column] = rounded_subtract(matrix[row*n+column], sum)
		}
		pivot := upper[row*n+row]
		if pivot == 0 || math.is_nan(pivot) || math.is_inf(pivot) do return -1
		lower[row*n+row] = 1
		for lower_row := row+1; lower_row < n; lower_row += 1 {
			sum := f64(0)
			for index := 0; index < row; index += 1 {
				product := rounded_multiply(lower[lower_row*n+index], upper[index*n+row])
				sum = rounded_add(sum, product)
			}
			numerator := rounded_subtract(matrix[lower_row*n+row], sum)
			value := rounded_divide(numerator, pivot)
			if math.is_nan(value) || math.is_inf(value) do return -1
			lower[lower_row*n+row] = value
		}
	}
	for i := 0; i < n*n; i += 1 {
		if math.is_nan(lower[i]) || math.is_inf(lower[i]) || math.is_nan(upper[i]) || math.is_inf(upper[i]) do return -1
	}
	output_length := 2*n*n
	if output == nil || capacity < c.size_t(output_length) do return -2
	for i := 0; i < n*n; i += 1 { output[i] = lower[i] }
	for i := 0; i < n*n; i += 1 { output[n*n+i] = upper[i] }
	return i64(output_length)
}
