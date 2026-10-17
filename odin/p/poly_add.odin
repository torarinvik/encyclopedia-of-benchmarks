package poly_add

import "core:c"

MAX_TERMS :: 16
MAX_INPUT_VALUES :: 67
MAX_OUTPUT_TERMS :: 32

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte: int = 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
	}
}

validate_terms :: proc "contextless" (input: [^]i64, start, count: int) -> bool {
	previous_degree: i64 = 64
	for i := 0; i < count; i += 1 {
		coefficient := input[start + 2 * i]
		degree := input[start + 2 * i + 1]
		if coefficient < -1_000_000 || coefficient > 1_000_000 || degree < 0 || degree > 63 || degree >= previous_degree do return false
		previous_degree = degree
	}
	return true
}

@(export)
poly_add :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	count_a_value := input[0]
	if count_a_value < 1 || count_a_value > MAX_TERMS do return -1
	count_a := int(count_a_value)
	count_b_index := 1 + 2 * count_a
	if int(length) <= count_b_index do return -1
	count_b_value := input[count_b_index]
	if count_b_value < 1 || count_b_value > MAX_TERMS do return -1
	count_b := int(count_b_value)
	if int(length) != 2 + 2 * (count_a + count_b) do return -1

	start_a := 1
	start_b := count_b_index + 1
	if !validate_terms(input, start_a, count_a) || !validate_terms(input, start_b, count_b) do return -1

	coefficients: [MAX_OUTPUT_TERMS]i64
	degrees: [MAX_OUTPUT_TERMS]i64
	i, j, terms := 0, 0, 0
	for i < count_a && j < count_b {
		coefficient_a := input[start_a + 2 * i]
		degree_a := input[start_a + 2 * i + 1]
		coefficient_b := input[start_b + 2 * j]
		degree_b := input[start_b + 2 * j + 1]
		if degree_a > degree_b {
			coefficients[terms] = coefficient_a; degrees[terms] = degree_a; terms += 1; i += 1
		} else if degree_a < degree_b {
			coefficients[terms] = coefficient_b; degrees[terms] = degree_b; terms += 1; j += 1
		} else {
			coefficients[terms] = coefficient_a + coefficient_b; degrees[terms] = degree_a; terms += 1; i += 1; j += 1
		}
	}
	for i < count_a { coefficients[terms] = input[start_a + 2 * i]; degrees[terms] = input[start_a + 2 * i + 1]; terms += 1; i += 1 }
	for j < count_b { coefficients[terms] = input[start_b + 2 * j]; degrees[terms] = input[start_b + 2 * j + 1]; terms += 1; j += 1 }

	required := terms * 16
	if output == nil || int(output_capacity) < required do return -2
	for term := 0; term < terms; term += 1 {
		put_i64_le(output, term * 16, coefficients[term])
		put_i64_le(output, term * 16 + 8, degrees[term])
	}
	return i64(required)
}
