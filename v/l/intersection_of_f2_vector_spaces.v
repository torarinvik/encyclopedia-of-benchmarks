module intersection_of_f2_vector_spaces

const max_cases = 4
const max_vectors = 8
const max_bits = 30
const max_input_values = 1 + max_cases * (2 + 2 * max_vectors) + 1
const max_output_words = max_cases * (1 + max_vectors)
const max_vector = u32(0x3fffffff)

fn insert_independent(mut basis []u32, value u32) bool {
	mut row := value
	mut bit := max_bits - 1
	for bit >= 0 {
		mask := u32(1) << u32(bit)
		if row & mask != 0 {
			if basis[bit] != 0 {
				row ^= basis[bit]
			} else {
				basis[bit] = row
				return true
			}
		}
		bit--
	}
	return false
}

fn intersection_basis(left []u32, n int, right []u32, m int, mut output []u32) int {
	mut right_basis := []u32{len: max_bits}
	mut right_coeff := []u32{len: max_bits}
	for index in 0 .. m {
		mut row := right[index]
		mut coefficients := u32(1) << u32(index)
		mut bit := max_bits - 1
		for bit >= 0 {
			mask := u32(1) << u32(bit)
			if row & mask != 0 {
				if right_basis[bit] != 0 {
					row ^= right_basis[bit]
					coefficients ^= right_coeff[bit]
				} else {
					right_basis[bit] = row
					right_coeff[bit] = coefficients
					break
				}
			}
			bit--
		}
	}

	mut quotient_basis := []u32{len: max_bits}
	mut quotient_left_coeff := []u32{len: max_bits}
	mut quotient_right_coeff := []u32{len: max_bits}
	mut intersection := []u32{len: max_vectors}
	mut intersection_count := 0
	for index in 0 .. n {
		mut row := left[index]
		mut right_mask := u32(0)
		mut bit := max_bits - 1
		for bit >= 0 {
			mask := u32(1) << u32(bit)
			if row & mask != 0 && right_basis[bit] != 0 {
				row ^= right_basis[bit]
				right_mask ^= right_coeff[bit]
			}
			bit--
		}
		mut left_mask := u32(1) << u32(index)
		bit = max_bits - 1
		for bit >= 0 {
			mask := u32(1) << u32(bit)
			if row & mask != 0 {
				if quotient_basis[bit] != 0 {
					row ^= quotient_basis[bit]
					left_mask ^= quotient_left_coeff[bit]
					right_mask ^= quotient_right_coeff[bit]
				} else {
					quotient_basis[bit] = row
					quotient_left_coeff[bit] = left_mask
					quotient_right_coeff[bit] = right_mask
					break
				}
			}
			bit--
		}
		if row == 0 {
			mut common := u32(0)
			for source in 0 .. n {
				if (left_mask >> u32(source)) & 1 != 0 {
					common ^= left[source]
				}
			}
			intersection[intersection_count] = common
			intersection_count++
		}
	}

	mut rref := []u32{len: max_bits}
	for index in 0 .. intersection_count {
		mut row := intersection[index]
		mut bit := max_bits - 1
		for bit >= 0 {
			mask := u32(1) << u32(bit)
			if row & mask != 0 {
				if rref[bit] != 0 {
					row ^= rref[bit]
				} else {
					rref[bit] = row
					for pivot in 0 .. max_bits {
						if pivot != bit && ((rref[pivot] >> u32(bit)) & 1) != 0 {
							rref[pivot] ^= row
						}
					}
					break
				}
			}
			bit--
		}
	}
	mut output_count := 0
	for bit in 0 .. max_bits {
		pivot := max_bits - 1 - bit
		if rref[pivot] != 0 {
			output[output_count] = rref[pivot]
			output_count++
		}
	}
	return output_count
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

@[export: 'intersection_of_f2_vector_spaces']
pub fn intersection_of_f2_vector_spaces(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_values {
		return -1
	}
	case_count_value := unsafe { input[0] }
	if case_count_value < 1 || case_count_value > max_cases {
		return -1
	}
	case_count := int(case_count_value)
	mut staged := []i64{len: max_output_words}
	mut used := 0
	mut cursor := 1
	for _ in 0 .. case_count {
		if cursor >= length {
			return -1
		}
		n_value := unsafe { input[cursor] }
		cursor++
		if n_value < 0 || n_value > max_vectors {
			return -1
		}
		n := int(n_value)
		if cursor + n > length {
			return -1
		}
		mut left := []u32{len: max_vectors}
		mut left_check := []u32{len: max_bits}
		for index in 0 .. n {
			value := unsafe { input[cursor] }
			cursor++
			if value < 0 || value > i64(max_vector) {
				return -1
			}
			vector := u32(value)
			if !insert_independent(mut left_check, vector) {
				return -1
			}
			left[index] = vector
		}
		if cursor >= length {
			return -1
		}
		m_value := unsafe { input[cursor] }
		cursor++
		if m_value < 0 || m_value > max_vectors {
			return -1
		}
		m := int(m_value)
		if cursor + m > length {
			return -1
		}
		mut right := []u32{len: max_vectors}
		mut right_check := []u32{len: max_bits}
		for index in 0 .. m {
			value := unsafe { input[cursor] }
			cursor++
			if value < 0 || value > i64(max_vector) {
				return -1
			}
			vector := u32(value)
			if !insert_independent(mut right_check, vector) {
				return -1
			}
			right[index] = vector
		}
		mut basis := []u32{len: max_vectors}
		dimension := intersection_basis(left, n, right, m, mut basis)
		staged[used] = i64(dimension)
		used++
		for index in 0 .. dimension {
			staged[used] = i64(basis[index])
			used++
		}
	}
	if cursor != length {
		return -1
	}
	required := 8 * used
	if unsafe { output == nil } || capacity < usize(required) {
		return -2
	}
	for index in 0 .. used {
		store_i64_le(mut output, 8 * index, staged[index])
	}
	return i64(required)
}
