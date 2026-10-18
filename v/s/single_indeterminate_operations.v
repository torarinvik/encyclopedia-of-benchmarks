import math

fn finite(value f64) bool { return value.is_finite() }

fn exact_integer(value f64, minimum i64, maximum i64) bool {
	if !finite(value) || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

@[export: 'single_indeterminate_operations']
pub fn single_indeterminate_operations(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 22 { return -1 }
		input_count := int(input_length)
		for index in 0 .. input_count { if !finite(input[index]) { return -1 } }
		if !exact_integer(input[0], 0, 5) { return -1 }
		operation := int(input[0])
		mut cursor := 1
		if !exact_integer(input[cursor], 0, 8) { return -1 }
		degree_a := int(input[cursor])
		cursor++
		mut coefficients_a := [9]f64{}
		if cursor + degree_a + 1 > input_count { return -1 }
		for index in 0 .. degree_a + 1 {
			value := input[cursor + index]
			if value < -10 || value > 10 { return -1 }
			coefficients_a[index] = value
		}
		cursor += degree_a + 1

		mut degree_b := 0
		mut coefficients_b := [9]f64{}
		mut parameter := 0.0
		if operation <= 2 {
			if cursor >= input_count || !exact_integer(input[cursor], 0, 8) { return -1 }
			degree_b = int(input[cursor])
			cursor++
			if cursor + degree_b + 1 > input_count { return -1 }
			for index in 0 .. degree_b + 1 {
				value := input[cursor + index]
				if value < -10 || value > 10 { return -1 }
				coefficients_b[index] = value
			}
			cursor += degree_b + 1
			if cursor != input_count { return -1 }
		} else if operation == 3 || operation == 5 {
			if cursor + 1 != input_count { return -1 }
			parameter = input[cursor]
			if operation == 3 {
				if parameter < -2 || parameter > 2 { return -1 }
			} else if parameter < -10 || parameter > 10 { return -1 }
			cursor++
		} else if cursor != input_count { return -1 }

		mut staged := [17]f64{}
		mut result_length := 0
		match operation {
			0 {
				result_length = max(degree_a, degree_b) + 1
				if degree_a > degree_b {
					for index in 0 .. degree_a + 1 { staged[index] = coefficients_a[index] }
					for index in 0 .. degree_b + 1 { staged[index] += coefficients_b[index] }
				} else {
					for index in 0 .. degree_b + 1 { staged[index] = coefficients_b[index] }
					for index in 0 .. degree_a + 1 { staged[index] += coefficients_a[index] }
				}
			}
			1 {
				mut negated_b := [9]f64{}
				for index in 0 .. degree_b + 1 { negated_b[index] = coefficients_b[index] * -1.0 }
				result_length = max(degree_a, degree_b) + 1
				if degree_a > degree_b {
					for index in 0 .. degree_a + 1 { staged[index] = coefficients_a[index] }
					for index in 0 .. degree_b + 1 { staged[index] += negated_b[index] }
				} else {
					for index in 0 .. degree_b + 1 { staged[index] = negated_b[index] }
					for index in 0 .. degree_a + 1 { staged[index] += coefficients_a[index] }
				}
			}
			2 {
				result_length = degree_a + degree_b + 1
				for left in 0 .. degree_a + 1 {
					for right in 0 .. degree_b + 1 {
						staged[left + right] += coefficients_a[left] * coefficients_b[right]
					}
				}
			}
			3 {
				result_length = 1
				for index in 0 .. degree_a + 1 { staged[0] += coefficients_a[index] * math.pow(parameter, f64(index)) }
			}
			4 {
				result_length = degree_a
				for index in 0 .. degree_a { staged[index] = coefficients_a[index + 1] * f64(index + 1) }
			}
			5 {
				result_length = degree_a + 2
				staged[0] = parameter
				for index in 0 .. degree_a + 1 { staged[index + 1] = coefficients_a[index] / f64(index + 1) }
			}
		}
		for index in 0 .. result_length { if !finite(staged[index]) { return -1 } }
		if output == nil || capacity < usize(result_length) { return -2 }
		for index in 0 .. result_length { output[index] = staged[index] }
		return i64(result_length)
	}
}
