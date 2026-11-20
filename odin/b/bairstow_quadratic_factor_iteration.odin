package bairstow_quadratic_factor_iteration

import "core:c"

MAX_DEGREE :: 8
MAX_ITERATIONS :: 4
MAX_INPUT_LENGTH :: 14
MODULUS :: i64(998244353)

normalize :: proc "contextless" (value_input: i64) -> i64 {
	value := value_input % MODULUS
	if value < 0 { value += MODULUS }
	return value
}

power :: proc "contextless" (base_input, exponent_input: i64) -> i64 {
	base, exponent, result := normalize(base_input), exponent_input, i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % MODULUS }
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
bairstow_quadratic_factor_iteration :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) { return -1 }
	degree_value := input[0]
	if degree_value < 3 || degree_value > i64(MAX_DEGREE) { return -1 }
	degree := int(degree_value)
	if length != c.size_t(degree+5) { return -1 }
	coefficients: [MAX_DEGREE+1]i64
	for i := 0; i <= degree; i += 1 {
		coefficients[i] = input[1+i]
		if coefficients[i] < 0 || coefficients[i] >= MODULUS { return -1 }
	}
	s_value, t_value, iterations_value := input[degree+2], input[degree+3], input[degree+4]
	if coefficients[degree] == 0 || s_value < 0 || s_value >= MODULUS ||
		t_value < 0 || t_value >= MODULUS || iterations_value < 1 || iterations_value > i64(MAX_ITERATIONS) { return -1 }
	iterations := int(iterations_value)
	s_trace: [MAX_ITERATIONS+1]i64
	t_trace: [MAX_ITERATIONS+1]i64
	s_trace[0], t_trace[0] = s_value, t_value
	for step := 0; step < iterations; step += 1 {
		q: [MAX_DEGREE+2]i64
		r: [MAX_DEGREE+2]i64
		q[degree], r[degree] = coefficients[degree], coefficients[degree]
		for cursor := degree-1; cursor >= 0; cursor -= 1 {
			q[cursor] = normalize(coefficients[cursor] + s_value*q[cursor+1] + t_value*q[cursor+2])
			r[cursor] = normalize(q[cursor] + s_value*r[cursor+1] + t_value*r[cursor+2])
		}
		r2, r3, q0, q1 := r[2], r[3], q[0], q[1]
		ell := normalize(s_value*r2 + t_value*r3)
		denominator := normalize(r2*r2 - ell*r3)
		if denominator == 0 { return -1 }
		inverse := power(denominator, MODULUS-2)
		delta_s := normalize(r3*q0-r2*q1) * inverse % MODULUS
		delta_t := normalize(ell*q1-r2*q0) * inverse % MODULUS
		s_value, t_value = normalize(s_value+delta_s), normalize(t_value+delta_t)
		s_trace[step+1], t_trace[step+1] = s_value, t_value
	}
	output_bytes := 8*(2*iterations+3)
	if output == nil || capacity < c.size_t(output_bytes) { return -2 }
	store_i64_le(output, 0, i64(iterations+1))
	for i := 0; i <= iterations; i += 1 {
		store_i64_le(output, 8*(1+2*i), s_trace[i])
		store_i64_le(output, 8*(2+2*i), t_trace[i])
	}
	return i64(output_bytes)
}
