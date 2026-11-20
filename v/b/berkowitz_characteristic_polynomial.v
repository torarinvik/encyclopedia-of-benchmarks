module berkowitz_characteristic_polynomial

const max_n = 7
const max_input_words = 52

fn residue(value i64, modulus i64) i64 {
	mut result := value % modulus
	if result < 0 { result += modulus }
	return result
}

fn negative_residue(value i64, modulus i64) i64 {
	if value == 0 { return 0 }
	return modulus - value
}

fn store_i64_le(mut output &u8, word int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[word * 8 + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'berkowitz_characteristic_polynomial']
pub fn berkowitz_characteristic_polynomial(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_words { return -1 }
	n64 := unsafe { input[0] }
	modulus := unsafe { input[1] }
	if n64 < 1 || n64 > max_n || modulus < 2 || modulus > 1000000000 { return -1 }
	n := int(n64)
	if int(length) != 2 + n * n { return -1 }

	mut matrix := [max_n * max_n]i64{}
	for i in 0 .. n * n {
		entry := unsafe { input[i + 2] }
		if entry < -1000000 || entry > 1000000 { return -1 }
		matrix[i] = residue(entry, modulus)
	}
	output_bytes := (n + 1) * 8
	if output == nil || output_capacity < usize(output_bytes) { return -2 }

	mut coefficients := [max_n + 1]i64{}
	mut current := [max_n + 1]i64{}
	mut toeplitz := [max_n + 1]i64{}
	mut vector := [max_n]i64{}
	mut next_vector := [max_n]i64{}
	coefficients[0] = 1
	for size in 1 .. n + 1 {
		start := n - size
		block := size - 1
		for i in 0 .. size + 1 { toeplitz[i] = 0 }
		toeplitz[0] = 1
		toeplitz[1] = negative_residue(matrix[start * n + start], modulus)
		for row in 0 .. block { vector[row] = matrix[(start + 1 + row) * n + start] }
		for power in 0 .. block {
			mut dot := i64(0)
			for col in 0 .. block {
				dot = (dot + matrix[start * n + start + 1 + col] * vector[col]) % modulus
			}
			toeplitz[power + 2] = negative_residue(dot, modulus)
			for row in 0 .. block {
				mut value := i64(0)
				for col in 0 .. block {
					value = (value + matrix[(start + 1 + row) * n + start + 1 + col]
						* vector[col]) % modulus
				}
				next_vector[row] = value
			}
			for row in 0 .. block { vector[row] = next_vector[row] }
		}
		for i in 0 .. size + 1 {
			mut value := i64(0)
			last_child := if i < size - 1 { i } else { size - 1 }
			for j in 0 .. last_child + 1 {
				value = (value + toeplitz[i - j] * coefficients[j]) % modulus
			}
			current[i] = value
		}
		for i in 0 .. size + 1 { coefficients[i] = current[i] }
	}
	for i in 0 .. n + 1 { store_i64_le(mut output, i, coefficients[i]) }
	return i64(output_bytes)
}
