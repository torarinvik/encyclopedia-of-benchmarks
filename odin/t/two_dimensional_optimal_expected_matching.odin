package two_dimensional_optimal_expected_matching

import "core:c"

MAX_SIDE :: 12
MAX_CELLS :: MAX_SIDE * MAX_SIDE
MAX_INPUT_LENGTH :: 2 + 2 * MAX_CELLS
MAX_PARSEABLE_INPUT_LENGTH :: MAX_INPUT_LENGTH + 1

sample_code :: proc(input: [^]i64, base, side, row, column, count, stride: int) -> int {
	code := 0
	for offset := 0; offset < count; offset += 1 {
		at := base + row * side + column + offset * stride
		code = 4 * code + int(input[at])
	}
	return code
}

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
two_dimensional_optimal_expected_matching :: proc "c"(input: [^]i64,
		length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	n_value, m_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_SIDE || m_value < 1 || m_value > n_value do return -1
	n, m := int(n_value), int(m_value)
	text_size, pattern_size := n * n, m * m
	if length != c.size_t(2 + text_size + pattern_size) do return -1
	pattern_base := 2 + text_size
	for index := 0; index < text_size + pattern_size; index += 1 {
		if input[2 + index] < 0 || input[2 + index] > 3 do return -1
	}
	q, code_capacity := 1, 4
	for code_capacity < pattern_size { q += 1; code_capacity *= 4 }
	stride := m / q
	final_offset := (q - 1) * stride
	var heads: [256]i16
	for code := 0; code < 256; code += 1 { heads[code] = -1 }
	var next_address: [MAX_CELLS]i16
	var address_row, address_column: [MAX_CELLS]u8
	address_count := 0
	for row := 0; row < m; row += 1 {
		for residue := 0; residue < stride; residue += 1 {
			code := sample_code(input, pattern_base, m, row, residue, q, stride)
			address_row[address_count], address_column[address_count] = u8(row), u8(residue)
			next_address[address_count] = heads[code]
			heads[code] = i16(address_count)
			address_count += 1
		}
	}
	var tested, matched: [MAX_CELLS]bool
	row_starts, column_starts := n - m + 1, n - m + 1
	for text_row := 0; text_row < n; text_row += m {
		for text_column := 0; text_column + final_offset < n; text_column += stride {
			code := sample_code(input, 2, n, text_row, text_column, q, stride)
			address := heads[code]
			for address >= 0 {
				slot := int(address)
				candidate_row := text_row - int(address_row[slot])
				candidate_column := text_column - int(address_column[slot])
				if candidate_row >= 0 && candidate_column >= 0 && candidate_row < row_starts && candidate_column < column_starts {
					candidate := candidate_row * n + candidate_column
					if !tested[candidate] {
						tested[candidate] = true
						equal := true
						for pattern_row := 0; pattern_row < m && equal; pattern_row += 1 {
							for pattern_column := 0; pattern_column < m; pattern_column += 1 {
								text_at := 2 + (candidate_row + pattern_row) * n + candidate_column + pattern_column
								pattern_at := pattern_base + pattern_row * m + pattern_column
								if input[text_at] != input[pattern_at] { equal = false; break }
							}
						}
						matched[candidate] = equal
					}
				}
				address = next_address[slot]
			}
		}
	}
	match_count := 0
	for row := 0; row < row_starts; row += 1 {
		for column := 0; column < column_starts; column += 1 {
			if matched[row*n+column] { match_count += 1 }
		}
	}
	output_bytes := 8 * (1 + 2 * match_count)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	put_i64_le(output, 0, i64(match_count))
	output_word := 1
	for row := 0; row < row_starts; row += 1 {
		for column := 0; column < column_starts; column += 1 {
			if matched[row*n+column] {
				put_i64_le(output, 8*output_word, i64(row)); output_word += 1
				put_i64_le(output, 8*output_word, i64(column)); output_word += 1
			}
		}
	}
	return i64(output_bytes)
}
