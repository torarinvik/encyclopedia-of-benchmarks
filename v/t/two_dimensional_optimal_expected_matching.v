@[export: 'two_dimensional_optimal_expected_matching']
pub fn two_dimensional_optimal_expected_matching(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 291 { return -1 }
		n_value, m_value := input[0], input[1]
		if n_value < 1 || n_value > 12 || m_value < 1 || m_value > n_value { return -1 }
		n, m := int(n_value), int(m_value)
		text_size, pattern_size := n * n, m * m
		if length != usize(2 + text_size + pattern_size) { return -1 }
		pattern_base := 2 + text_size
		for index in 0 .. (text_size + pattern_size) {
			if input[2 + index] < 0 || input[2 + index] > 3 { return -1 }
		}
		mut q, mut code_capacity := 1, 4
		for code_capacity < pattern_size { q++; code_capacity *= 4 }
		stride := m / q
		final_offset := (q - 1) * stride
		mut heads := [256]i16{init: -1}
		mut next_address := [144]i16{}
		mut address_row, mut address_column := [144]u8{}, [144]u8{}
		mut address_count := 0
		for row in 0 .. m {
			for residue in 0 .. stride {
				code := sample_code(input, pattern_base, m, row, residue, q, stride)
				address_row[address_count], address_column[address_count] = u8(row), u8(residue)
				next_address[address_count] = heads[code]
				heads[code] = i16(address_count)
				address_count++
			}
		}
		mut tested, mut matched := [144]bool{}, [144]bool{}
		row_starts, column_starts := n - m + 1, n - m + 1
		for text_row := 0; text_row < n; text_row += m {
			for text_column := 0; text_column + final_offset < n; text_column += stride {
				code := sample_code(input, 2, n, text_row, text_column, q, stride)
				mut address := heads[code]
				for address >= 0 {
					slot := int(address)
					candidate_row := text_row - int(address_row[slot])
					candidate_column := text_column - int(address_column[slot])
					if candidate_row >= 0 && candidate_column >= 0 && candidate_row < row_starts && candidate_column < column_starts {
						candidate := candidate_row * n + candidate_column
						if !tested[candidate] {
							tested[candidate] = true
							mut equal := true
							for pattern_row in 0 .. m {
								for pattern_column in 0 .. m {
									text_at := 2 + (candidate_row + pattern_row) * n + candidate_column + pattern_column
									pattern_at := pattern_base + pattern_row * m + pattern_column
									if input[text_at] != input[pattern_at] { equal = false; break }
								}
								if !equal { break }
							}
							matched[candidate] = equal
						}
					}
					address = next_address[slot]
				}
			}
		}
		mut match_count := 0
		for row in 0 .. row_starts {
			for column in 0 .. column_starts {
				if matched[row * n + column] { match_count++ }
			}
		}
		output_bytes := 8 * (1 + 2 * match_count)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		put_i64_le(output, 0, i64(match_count))
		mut output_word := 1
		for row in 0 .. row_starts {
			for column in 0 .. column_starts {
				if matched[row * n + column] {
					put_i64_le(output, 8 * output_word, i64(row)); output_word++
					put_i64_le(output, 8 * output_word, i64(column)); output_word++
				}
			}
		}
		return i64(output_bytes)
	}
}

fn sample_code(input &i64, base int, side int, row int, column int, count int, stride int) int {
	unsafe {
		mut code := 0
		for offset in 0 .. count {
			at := base + row * side + column + offset * stride
			code = 4 * code + int(input[at])
		}
		return code
	}
}

fn put_i64_le(output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}
