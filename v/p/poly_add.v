module poly_add

const max_terms = 16
const max_input_values = 67
const max_output_terms = 32

fn poly_add_validate_terms(input &i64, start int, count int) bool {
	mut previous_degree := i64(64)
	for i in 0 .. count {
		coefficient := unsafe { input[start + 2 * i] }
		degree := unsafe { input[start + 2 * i + 1] }
		if coefficient < -1000000 || coefficient > 1000000 || degree < 0 || degree > 63 || degree >= previous_degree {
			return false
		}
		previous_degree = degree
	}
	return true
}

fn poly_add_put_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
		}
	}
}

@[export: 'poly_add']
pub fn poly_add(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values { return -1 }
	count_a_value := unsafe { input[0] }
	if count_a_value < 1 || count_a_value > max_terms { return -1 }
	count_a := int(count_a_value)
	count_b_index := 1 + 2 * count_a
	if int(length) <= count_b_index { return -1 }
	count_b_value := unsafe { input[count_b_index] }
	if count_b_value < 1 || count_b_value > max_terms { return -1 }
	count_b := int(count_b_value)
	if int(length) != 2 + 2 * (count_a + count_b) { return -1 }

	start_a := 1
	start_b := count_b_index + 1
	if !poly_add_validate_terms(input, start_a, count_a) || !poly_add_validate_terms(input, start_b, count_b) { return -1 }

	mut coefficients := [max_output_terms]i64{}
	mut degrees := [max_output_terms]i64{}
	mut i, mut j, mut terms := 0, 0, 0
	unsafe {
		for i < count_a && j < count_b {
			coefficient_a := input[start_a + 2 * i]
			degree_a := input[start_a + 2 * i + 1]
			coefficient_b := input[start_b + 2 * j]
			degree_b := input[start_b + 2 * j + 1]
			if degree_a > degree_b {
				coefficients[terms] = coefficient_a; degrees[terms] = degree_a; terms++; i++
			} else if degree_a < degree_b {
				coefficients[terms] = coefficient_b; degrees[terms] = degree_b; terms++; j++
			} else {
				coefficients[terms] = coefficient_a + coefficient_b; degrees[terms] = degree_a; terms++; i++; j++
			}
		}
		for i < count_a { coefficients[terms] = input[start_a + 2 * i]; degrees[terms] = input[start_a + 2 * i + 1]; terms++; i++ }
		for j < count_b { coefficients[terms] = input[start_b + 2 * j]; degrees[terms] = input[start_b + 2 * j + 1]; terms++; j++ }
	}

	required := terms * 16
	if unsafe { output == nil } || output_capacity < usize(required) { return -2 }
	for term in 0 .. terms {
		poly_add_put_i64_le(output, term * 16, coefficients[term])
		poly_add_put_i64_le(output, term * 16 + 8, degrees[term])
	}
	return i64(required)
}
