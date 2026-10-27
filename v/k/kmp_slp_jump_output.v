module kmp_slp_jump_output

import core.c

const (
	max_pattern = 6
	max_variables = 12
	max_factors = 8
	max_text = 64
	max_input = 53
	max_output_bytes = 520
)

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'kmp_slp_jump_output']
pub fn kmp_slp_jump_output(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 8 || length > max_input { return -1 }
		mut cursor := 0
		pattern_raw := input[cursor]; cursor++
		if pattern_raw < 1 || pattern_raw > max_pattern { return -1 }
		pattern_length := int(pattern_raw)
		mut pattern := [max_pattern]i64{}
		for i in 0 .. pattern_length { pattern[i] = input[cursor]; cursor++; if pattern[i] < 0 || pattern[i] > 3 { return -1 } }
		if cursor >= int(length) { return -1 }
		variable_raw := input[cursor]; cursor++
		if variable_raw < 1 || variable_raw > max_variables || cursor + 3 * int(variable_raw) + 1 > int(length) { return -1 }
		variable_count := int(variable_raw)
		mut kind := [max_variables]int{}
		mut first := [max_variables]int{}
		mut second := [max_variables]int{}
		mut terminal := [max_variables]i64{}
		mut variable_length := [max_variables]int{}
		for variable in 0 .. variable_count {
			kind_raw := input[cursor]; first_raw := input[cursor + 1]; second_raw := input[cursor + 2]; cursor += 3
			if kind_raw == 0 {
				if first_raw < 0 || first_raw > 3 || second_raw != 0 { return -1 }
				terminal[variable] = first_raw
				variable_length[variable] = 1
			} else if kind_raw == 1 {
				if first_raw < 0 || second_raw < 0 || first_raw >= i64(variable) || second_raw >= i64(variable) { return -1 }
				kind[variable] = 1
				first[variable] = int(first_raw); second[variable] = int(second_raw)
				variable_length[variable] = variable_length[first[variable]] + variable_length[second[variable]]
				if variable_length[variable] > max_text { return -1 }
			} else { return -1 }
		}
		if cursor >= int(length) { return -1 }
		factor_raw := input[cursor]; cursor++
		if factor_raw < 1 || factor_raw > max_factors || cursor + int(factor_raw) != int(length) { return -1 }
		factor_count := int(factor_raw)
		mut factors := [max_factors]int{}
		mut text_length := 0
		for i in 0 .. factor_count {
			factor := input[cursor]; cursor++
			if factor < 0 || factor >= variable_raw { return -1 }
			factors[i] = int(factor)
			text_length += variable_length[factors[i]]
			if text_length > max_text { return -1 }
		}
		mut failure := [max_pattern]int{}
		mut border := 0
		for i in 1 .. pattern_length {
			for border > 0 && pattern[i] != pattern[border] { border = failure[border - 1] }
			if pattern[i] == pattern[border] { border++ }
			failure[i] = border
		}
		mut jump := [max_variables][max_pattern]int{}
		mut output_mask := [max_variables][max_pattern]u64{}
		for variable in 0 .. variable_count { for state in 0 .. pattern_length {
			if kind[variable] == 0 {
				mut next := state
				for next > 0 && pattern[next] != terminal[variable] { next = failure[next - 1] }
				if pattern[next] == terminal[variable] { next++ }
				if next == pattern_length { output_mask[variable][state] = 1; next = failure[pattern_length - 1] }
				jump[variable][state] = next
			} else {
				left := first[variable]; right := second[variable]
				middle := jump[left][state]
				jump[variable][state] = jump[right][middle]
				output_mask[variable][state] = output_mask[left][state] | (output_mask[right][middle] << variable_length[left])
			}
		} }
		mut state := 0
		mut offset := 0
		mut end_offsets := u64(0)
		for i in 0 .. factor_count {
			variable := factors[i]
			end_offsets |= output_mask[variable][state] << offset
			state = jump[variable][state]
			offset += variable_length[variable]
		}
		mut words := [1 + max_text]i64{}
		mut occurrences := 0
		for ending in 0 .. text_length {
			if ((end_offsets >> ending) & 1) != 0 {
				if ending + 1 < pattern_length { return -1 }
				words[1 + occurrences] = i64(ending + 1 - pattern_length)
				occurrences++
			}
		}
		words[0] = i64(occurrences)
		output_bytes := 8 * (1 + occurrences)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{}
		for word in 0 .. 1 + occurrences { put_i64_le(mut staged[0], 8 * word, words[word]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
