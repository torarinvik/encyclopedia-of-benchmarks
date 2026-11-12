module polynomial_interpolation_on_geometric_sequence

const modulus = i64(998244353)
const max_n = 8
const max_input = 11

fn normalize(value i64) i64 {
	reduced := value % modulus
	if reduced < 0 { return reduced + modulus }
	return reduced
}

fn power_mod(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'polynomial_interpolation_on_geometric_sequence']
pub fn polynomial_interpolation_on_geometric_sequence(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n_value := input[0]
		if n_value < 0 || n_value > max_n { return -1 }
		n := int(n_value)
		a := input[1]
		r := input[2]
		if length != usize(3 + n) || a < 0 || a >= modulus || r < 0 || r >= modulus { return -1 }
		mut points := [max_n]i64{}
		mut differences := [max_n]i64{}
		mut newton := [max_n]i64{}
		mut point := a
		for i in 0 .. n {
			points[i] = point
			differences[i] = input[3 + i]
			if differences[i] < 0 || differences[i] >= modulus { return -1 }
			for j in 0 .. i {
				if points[i] == points[j] { return -1 }
			}
			point = point * r % modulus
		}
		bytes := 8 * n
		if output == nil || capacity < usize(bytes) { return -2 }
		if n == 0 { return 0 }
		newton[0] = differences[0]
		for order in 1 .. n {
			r_order := power_mod(r, i64(order))
			mut end := n
			for end > order {
				end--
				r_factor := power_mod(r, i64(end - order))
				mut denominator := a * r_factor % modulus
				denominator = denominator * (r_order - 1) % modulus
				inverse := power_mod(normalize(denominator), modulus - 2)
				differences[end] = normalize((differences[end] - differences[end - 1]) * inverse)
			}
			newton[order] = differences[order]
		}
		mut coefficients := [max_n]i64{}
		mut basis := [max_n + 1]i64{}
		basis[0] = 1
		mut degree := 0
		for order in 0 .. n {
			for k in 0 .. degree + 1 {
				coefficients[k] = (coefficients[k] + newton[order] * basis[k]) % modulus
			}
			if order + 1 == n { break }
			mut expanded := [max_n + 1]i64{}
			for k in 0 .. degree + 1 {
				expanded[k] = normalize(expanded[k] - basis[k] * points[order])
				expanded[k + 1] = normalize(expanded[k + 1] + basis[k])
			}
			for k in 0 .. degree + 2 { basis[k] = expanded[k] }
			degree++
		}
		for i in 0 .. n { store_le(mut output, 8 * i, coefficients[i]) }
		return i64(bytes)
	}
}
