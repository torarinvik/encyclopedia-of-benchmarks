fn km_sample_code(input &i64, base int, side int, row int, column int, q int, stride int) int {
	unsafe {
		mut code := 0
		for step in 0 .. q {
			at := base + row * side + column + step * stride
			code = 4 * code + int(input[at])
		}
		return code
	}
}

fn km_put_i64_le(output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8((bits >> (8 * byte)) & 255)
		}
	}
}

@[export: 'two_dimensional_k_mismatch_linear_templates']
pub fn two_dimensional_k_mismatch_linear_templates(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 291 { return -1 }
		n_value, m_value := input[0], input[1]
		if n_value < 3 || n_value > 12 || m_value < 3 || m_value > n_value { return -1 }
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
		mut sample_row, mut sample_column := [144]u8{}, [144]u8{}
		mut sample_count := 0
		for row in 0 .. m {
			for residue in 0 .. stride {
				code := km_sample_code(input, pattern_base, m, row, residue, q, stride)
				sample_row[sample_count], sample_column[sample_count] = u8(row), u8(residue)
				next_address[sample_count] = heads[code]
				heads[code] = i16(sample_count)
				sample_count++
			}
		}
		mut considered, mut matched := [144]bool{}, [144]bool{}
		starts := n - m + 1
		for text_row := 0; text_row < n; text_row++ {
			if text_row % m < m - 2 { continue }
			for text_column := 0; text_column + final_offset < n; text_column += stride {
				code := km_sample_code(input, 2, n, text_row, text_column, q, stride)
				mut address := heads[code]
				for address >= 0 {
					slot := int(address)
					candidate_row := text_row - int(sample_row[slot])
					candidate_column := text_column - int(sample_column[slot])
					if candidate_row >= 0 && candidate_column >= 0 && candidate_row < starts && candidate_column < starts {
						candidate := candidate_row * n + candidate_column
						if !considered[candidate] {
							considered[candidate] = true
							mut mismatches := 0
						for dr := 0; dr < m && mismatches < 2; dr++ {
							for dc := 0; dc < m; dc++ {
								text_at := 2 + (candidate_row + dr) * n + candidate_column + dc
								pattern_at := pattern_base + dr * m + dc
								if input[text_at] != input[pattern_at] {
									mismatches++
									if mismatches == 2 { break }
								}
							}
						}
						matched[candidate] = mismatches <= 1
						}
					}
					address = next_address[slot]
				}
			}
		}
		mut match_count := 0
		for row in 0 .. starts {
			for column in 0 .. starts {
				if matched[row * n + column] { match_count++ }
			}
		}
		output_bytes := 8 * (1 + 2 * match_count)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		km_put_i64_le(output, 0, i64(match_count))
		mut word := 1
		for row in 0 .. starts {
			for column in 0 .. starts {
				if matched[row * n + column] {
					km_put_i64_le(output, 8 * word, i64(row)); word++
					km_put_i64_le(output, 8 * word, i64(column)); word++
				}
			}
		}
		return i64(output_bytes)
	}
}
