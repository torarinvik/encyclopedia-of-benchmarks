const pade_modulus = i64(998244353)
const pade_max_input_length = 12

fn pade_mod_pow(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % pade_modulus }
		base = base * base % pade_modulus
		exponent >>= 1
	}
	return result
}

fn pade_store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
		}
	}
}

@[export: 'pade_approximant_series_coefficients']
pub fn pade_approximant_series_coefficients(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > pade_max_input_length { return -1 }
		p_value := input[0]
		q_value := input[1]
		if q_value < 1 || p_value < q_value || p_value > 4 || q_value > 4 || int(length) != int(p_value + q_value + 3) { return -1 }
		p, q := int(p_value), int(q_value)
		mut coefficients := [9]u32{}
		for i in 0 .. p + q + 1 {
			if input[i + 2] < 0 || input[i + 2] >= pade_modulus { return -1 }
			coefficients[i] = u32(input[i + 2])
		}
		required := 8 * (p + q + 4)
		if output == nil || capacity < usize(required) { return -2 }

		mut matrix := [4][5]u32{}
		for row in 0 .. q {
			m := p + 1 + row
			for col in 0 .. q { matrix[row][col] = coefficients[m - col - 1] }
			matrix[row][q] = u32((pade_modulus - i64(coefficients[m])) % pade_modulus)
		}
		for col in 0 .. q {
			mut pivot := col
			for pivot < q && matrix[pivot][col] == 0 { pivot++ }
			if pivot == q { return -3 }
			if pivot != col {
				for j in 0 .. q + 1 { matrix[col][j], matrix[pivot][j] = matrix[pivot][j], matrix[col][j] }
			}
			inverse := pade_mod_pow(i64(matrix[col][col]), pade_modulus - 2)
			for j in col .. q + 1 { matrix[col][j] = u32(i64(matrix[col][j]) * inverse % pade_modulus) }
			for row in 0 .. q {
				if row == col { continue }
				factor := i64(matrix[row][col])
				for j in col .. q + 1 {
					product := factor * i64(matrix[col][j]) % pade_modulus
					mut difference := i64(matrix[row][j]) - product
					if difference < 0 { difference += pade_modulus }
					matrix[row][j] = u32(difference)
				}
			}
		}
		pade_store_i64_le(mut output, 0, p_value)
		pade_store_i64_le(mut output, 8, q_value)
		mut offset := 16
		for m in 0 .. p + 1 {
			mut value := u64(coefficients[m])
			last := if m < q { m } else { q }
			for j in 1 .. last + 1 { value = (value + u64(coefficients[m-j]) * u64(matrix[j-1][q])) % u64(pade_modulus) }
			pade_store_i64_le(mut output, offset, i64(value))
			offset += 8
		}
		pade_store_i64_le(mut output, offset, 1)
		offset += 8
		for j in 0 .. q {
			pade_store_i64_le(mut output, offset, i64(matrix[j][q]))
			offset += 8
		}
		return i64(required)
	}
}
