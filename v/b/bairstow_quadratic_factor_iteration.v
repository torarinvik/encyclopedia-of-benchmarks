module bairstow_quadratic_factor_iteration

const max_degree = 8
const max_iterations = 4
const max_input_length = 14
const modulus = i64(998244353)

fn normalize(input i64) i64 {
	mut value := input % modulus
	if value < 0 { value += modulus }
	return value
}

fn power(base_input i64, exponent_input i64) i64 {
	mut base := normalize(base_input)
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'bairstow_quadratic_factor_iteration']
pub fn bairstow_quadratic_factor_iteration(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length { return -1 }
		degree_value := input[0]
		if degree_value < 3 || degree_value > max_degree { return -1 }
		degree := int(degree_value)
		if length != usize(degree + 5) { return -1 }
		mut coefficients := [max_degree + 1]i64{}
		for i in 0 .. degree + 1 {
			coefficients[i] = input[1 + i]
			if coefficients[i] < 0 || coefficients[i] >= modulus { return -1 }
		}
		mut s_value := input[degree + 2]
		mut t_value := input[degree + 3]
		iterations_value := input[degree + 4]
		if coefficients[degree] == 0 || s_value < 0 || s_value >= modulus
				|| t_value < 0 || t_value >= modulus || iterations_value < 1
				|| iterations_value > max_iterations { return -1 }
		iterations := int(iterations_value)
		mut s_trace := [max_iterations + 1]i64{}
		mut t_trace := [max_iterations + 1]i64{}
		s_trace[0], t_trace[0] = s_value, t_value
		for step in 0 .. iterations {
			mut q := [max_degree + 2]i64{}
			mut r := [max_degree + 2]i64{}
			q[degree], r[degree] = coefficients[degree], coefficients[degree]
			for cursor := degree - 1; cursor >= 0; cursor-- {
				q[cursor] = normalize(coefficients[cursor] + s_value * q[cursor + 1]
					+ t_value * q[cursor + 2])
				r[cursor] = normalize(q[cursor] + s_value * r[cursor + 1]
					+ t_value * r[cursor + 2])
			}
			r2, r3, q0, q1 := r[2], r[3], q[0], q[1]
			ell := normalize(s_value * r2 + t_value * r3)
			denominator := normalize(r2 * r2 - ell * r3)
			if denominator == 0 { return -1 }
			inverse := power(denominator, modulus - 2)
			delta_s := normalize(r3 * q0 - r2 * q1) * inverse % modulus
			delta_t := normalize(ell * q1 - r2 * q0) * inverse % modulus
			s_value, t_value = normalize(s_value + delta_s), normalize(t_value + delta_t)
			s_trace[step + 1], t_trace[step + 1] = s_value, t_value
		}
		output_bytes := 8 * (2 * iterations + 3)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		store_i64_le(mut output, 0, i64(iterations + 1))
		for i in 0 .. iterations + 1 {
			store_i64_le(mut output, 8 * (1 + 2 * i), s_trace[i])
			store_i64_le(mut output, 8 * (2 + 2 * i), t_trace[i])
		}
		return i64(output_bytes)
	}
}
