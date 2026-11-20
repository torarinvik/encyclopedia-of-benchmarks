package two_dimensional_k_mismatch_linear_templates

import "core:c"

KM_MAX_SIDE :: 12
KM_MAX_CELLS :: KM_MAX_SIDE * KM_MAX_SIDE
KM_MAX_PARSEABLE_INPUT_LENGTH :: 2 + 2 * KM_MAX_CELLS + 1

km_sample_code :: proc(input: [^]i64, base, side, row, column, q, stride: int) -> int {
	code := 0
	for step := 0; step < q; step += 1 {
		at := base + row * side + column + step * stride
		code = 4 * code + int(input[at])
	}
	return code
}

km_put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
two_dimensional_k_mismatch_linear_templates :: proc "c"(input: [^]i64,
		length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > KM_MAX_PARSEABLE_INPUT_LENGTH do return -1
	n_value, m_value := input[0], input[1]
	if n_value < 3 || n_value > KM_MAX_SIDE || m_value < 3 || m_value > n_value do return -1
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
	var next_address: [KM_MAX_CELLS]i16
	var sample_row, sample_column: [KM_MAX_CELLS]u8
	sample_count := 0
	for row := 0; row < m; row += 1 {
		for residue := 0; residue < stride; residue += 1 {
			code := km_sample_code(input, pattern_base, m, row, residue, q, stride)
			sample_row[sample_count], sample_column[sample_count] = u8(row), u8(residue)
			next_address[sample_count] = heads[code]
			heads[code] = i16(sample_count)
			sample_count += 1
		}
	}
	var considered, matched: [KM_MAX_CELLS]bool
	starts := n - m + 1
	for text_row := 0; text_row < n; text_row += 1 {
		if text_row % m >= m - 2 {
			for text_column := 0; text_column + final_offset < n; text_column += stride {
				code := km_sample_code(input, 2, n, text_row, text_column, q, stride)
				address := heads[code]
				for address >= 0 {
					slot := int(address)
					candidate_row := text_row - int(sample_row[slot])
					candidate_column := text_column - int(sample_column[slot])
					if candidate_row >= 0 && candidate_column >= 0 && candidate_row < starts && candidate_column < starts {
						candidate := candidate_row * n + candidate_column
						if !considered[candidate] {
							considered[candidate] = true
							mismatches := 0
						for dr := 0; dr < m && mismatches < 2; dr += 1 {
							for dc := 0; dc < m; dc += 1 {
								text_at := 2 + (candidate_row + dr) * n + candidate_column + dc
								pattern_at := pattern_base + dr * m + dc
								if input[text_at] != input[pattern_at] {
									mismatches += 1
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
	}
	match_count := 0
	for row := 0; row < starts; row += 1 {
		for column := 0; column < starts; column += 1 {
			if matched[row*n+column] { match_count += 1 }
		}
	}
	output_bytes := 8 * (1 + 2 * match_count)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	km_put_i64_le(output, 0, i64(match_count))
	word := 1
	for row := 0; row < starts; row += 1 {
		for column := 0; column < starts; column += 1 {
			if matched[row*n+column] {
				km_put_i64_le(output, 8*word, i64(row)); word += 1
				km_put_i64_le(output, 8*word, i64(column)); word += 1
			}
		}
	}
	return i64(output_bytes)
}
