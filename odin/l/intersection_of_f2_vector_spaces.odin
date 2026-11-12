package intersection_of_f2_vector_spaces

import "core:c"

MAX_CASES :: 4
MAX_VECTORS :: 8
MAX_BITS :: 30
MAX_INPUT_VALUES :: 1 + MAX_CASES * (2 + 2 * MAX_VECTORS) + 1
MAX_OUTPUT_WORDS :: MAX_CASES * (1 + MAX_VECTORS)
MAX_VECTOR :: u32(0x3fffffff)

insert_independent :: proc "contextless" (basis: [^]u32, value: u32) -> bool {
	row := value
	for bit: int = MAX_BITS - 1; bit >= 0; bit -= 1 {
		mask := u32(1) << u32(bit)
		if row & mask == 0 do continue
		if basis[bit] != 0 { row ^= basis[bit] } else { basis[bit] = row; return true }
	}
	return false
}

intersection_basis :: proc "contextless" (left: [^]u32, n: int, right: [^]u32,
	m: int, output: [^]u32) -> int {
	right_basis: [MAX_BITS]u32
	right_coeff: [MAX_BITS]u32
	for bit := 0; bit < MAX_BITS; bit += 1 {
		right_basis[bit] = 0
		right_coeff[bit] = 0
	}
	for index := 0; index < m; index += 1 {
		row := right[index]
		coefficients := u32(1) << u32(index)
		for bit: int = MAX_BITS - 1; bit >= 0; bit -= 1 {
			mask := u32(1) << u32(bit)
			if row & mask == 0 do continue
			if right_basis[bit] != 0 {
				row ^= right_basis[bit]
				coefficients ^= right_coeff[bit]
			} else {
				right_basis[bit] = row
				right_coeff[bit] = coefficients
				break
			}
		}
	}
	quotient_basis: [MAX_BITS]u32
	quotient_left_coeff: [MAX_BITS]u32
	quotient_right_coeff: [MAX_BITS]u32
	for bit := 0; bit < MAX_BITS; bit += 1 {
		quotient_basis[bit] = 0
		quotient_left_coeff[bit] = 0
		quotient_right_coeff[bit] = 0
	}
	intersection: [MAX_VECTORS]u32
	intersection_count := 0
	for index := 0; index < MAX_VECTORS; index += 1 do intersection[index] = 0
	for index := 0; index < n; index += 1 {
		row := left[index]
		right_mask := u32(0)
		for bit: int = MAX_BITS - 1; bit >= 0; bit -= 1 {
			mask := u32(1) << u32(bit)
			if row & mask != 0 && right_basis[bit] != 0 {
				row ^= right_basis[bit]
				right_mask ^= right_coeff[bit]
			}
		}
		left_mask := u32(1) << u32(index)
		for bit: int = MAX_BITS - 1; bit >= 0; bit -= 1 {
			mask := u32(1) << u32(bit)
			if row & mask == 0 do continue
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
		if row == 0 {
			common := u32(0)
			for source := 0; source < n; source += 1 {
				if (left_mask >> u32(source)) & 1 != 0 do common ^= left[source]
			}
			intersection[intersection_count] = common
			intersection_count += 1
		}
	}

	rref: [MAX_BITS]u32
	for bit := 0; bit < MAX_BITS; bit += 1 do rref[bit] = 0
	for index := 0; index < intersection_count; index += 1 {
		row := intersection[index]
		for bit: int = MAX_BITS - 1; bit >= 0; bit -= 1 {
			mask := u32(1) << u32(bit)
			if row & mask == 0 do continue
			if rref[bit] != 0 { row ^= rref[bit] } else {
				rref[bit] = row
				for pivot := 0; pivot < MAX_BITS; pivot += 1 {
					if pivot != bit && ((rref[pivot] >> u32(bit)) & 1) != 0 do rref[pivot] ^= row
				}
				break
			}
		}
	}
	output_count := 0
	for bit: int = MAX_BITS - 1; bit >= 0; bit -= 1 {
		if rref[bit] != 0 {
			output[output_count] = rref[bit]
			output_count += 1
		}
	}
	return output_count
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) }
}

@(export)
intersection_of_f2_vector_spaces :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_VALUES do return -1
	case_count_value := input[0]
	if case_count_value < 1 || case_count_value > i64(MAX_CASES) do return -1
	case_count := int(case_count_value)
	staged: [MAX_OUTPUT_WORDS]i64
	used := 0
	cursor := 1
	for case_index := 0; case_index < case_count; case_index += 1 {
		if cursor >= int(length) do return -1
		n_value := input[cursor]
		cursor += 1
		if n_value < 0 || n_value > i64(MAX_VECTORS) do return -1
		n := int(n_value)
		if cursor + n > int(length) do return -1
		left: [MAX_VECTORS]u32
		left_check: [MAX_BITS]u32
		for bit := 0; bit < MAX_BITS; bit += 1 do left_check[bit] = 0
		for index := 0; index < n; index += 1 {
			value := input[cursor]
			cursor += 1
			if value < 0 || value > i64(MAX_VECTOR) do return -1
			vector := u32(value)
			if !insert_independent(&left_check[0], vector) do return -1
			left[index] = vector
		}
		if cursor >= int(length) do return -1
		m_value := input[cursor]
		cursor += 1
		if m_value < 0 || m_value > i64(MAX_VECTORS) do return -1
		m := int(m_value)
		if cursor + m > int(length) do return -1
		right: [MAX_VECTORS]u32
		right_check: [MAX_BITS]u32
		for bit := 0; bit < MAX_BITS; bit += 1 do right_check[bit] = 0
		for index := 0; index < m; index += 1 {
			value := input[cursor]
			cursor += 1
			if value < 0 || value > i64(MAX_VECTOR) do return -1
			vector := u32(value)
			if !insert_independent(&right_check[0], vector) do return -1
			right[index] = vector
		}
		basis: [MAX_VECTORS]u32
		dimension := intersection_basis(&left[0], n, &right[0], m, &basis[0])
		staged[used] = i64(dimension)
		used += 1
		for index := 0; index < dimension; index += 1 {
			staged[used] = i64(basis[index])
			used += 1
		}
	}
	if cursor != int(length) do return -1
	required := 8 * used
	if output == nil || capacity < c.size_t(required) do return -2
	for index := 0; index < used; index += 1 do store_i64_le(output, 8 * index, staged[index])
	return i64(required)
}
