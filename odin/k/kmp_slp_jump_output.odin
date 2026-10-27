package kmp_slp_jump_output

import "core:c"

MAX_PATTERN :: 6
MAX_VARIABLES :: 12
MAX_FACTORS :: 8
MAX_TEXT :: 64
MAX_INPUT :: 53
MAX_OUTPUT_BYTES :: 520

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
kmp_slp_jump_output :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 8 || length > MAX_INPUT do return -1
	cursor := 0
	pattern_raw := input[cursor]; cursor += 1
	if pattern_raw < 1 || pattern_raw > MAX_PATTERN do return -1
	pattern_length := int(pattern_raw)
	pattern: [MAX_PATTERN]i64 = {}
	for i := 0; i < pattern_length; i += 1 { pattern[i] = input[cursor]; cursor += 1; if pattern[i] < 0 || pattern[i] > 3 do return -1 }
	if cursor >= int(length) do return -1
	variable_raw := input[cursor]; cursor += 1
	if variable_raw < 1 || variable_raw > MAX_VARIABLES || cursor+3*int(variable_raw)+1 > int(length) do return -1
	variable_count := int(variable_raw)
	kind: [MAX_VARIABLES]int = {}
	first, second: [MAX_VARIABLES]int = {}, {}
	terminal: [MAX_VARIABLES]i64 = {}
	variable_length: [MAX_VARIABLES]int = {}
	for variable := 0; variable < variable_count; variable += 1 {
		kind_raw, first_raw, second_raw := input[cursor], input[cursor+1], input[cursor+2]; cursor += 3
		if kind_raw == 0 {
			if first_raw < 0 || first_raw > 3 || second_raw != 0 do return -1
			terminal[variable] = first_raw
			variable_length[variable] = 1
		} else if kind_raw == 1 {
			if first_raw < 0 || second_raw < 0 || first_raw >= i64(variable) || second_raw >= i64(variable) do return -1
			kind[variable] = 1
			first[variable] = int(first_raw); second[variable] = int(second_raw)
			variable_length[variable] = variable_length[first[variable]] + variable_length[second[variable]]
			if variable_length[variable] > MAX_TEXT do return -1
		} else { return -1 }
	}
	if cursor >= int(length) do return -1
	factor_raw := input[cursor]; cursor += 1
	if factor_raw < 1 || factor_raw > MAX_FACTORS || cursor+int(factor_raw) != int(length) do return -1
	factor_count := int(factor_raw)
	factors: [MAX_FACTORS]int = {}
	text_length := 0
	for i := 0; i < factor_count; i += 1 {
		factor := input[cursor]; cursor += 1
		if factor < 0 || factor >= variable_raw do return -1
		factors[i] = int(factor)
		text_length += variable_length[factors[i]]
		if text_length > MAX_TEXT do return -1
	}
	failure: [MAX_PATTERN]int = {}
	border := 0
	for i := 1; i < pattern_length; i += 1 {
		for border > 0 && pattern[i] != pattern[border] { border = failure[border-1] }
		if pattern[i] == pattern[border] { border += 1 }
		failure[i] = border
	}
	jump: [MAX_VARIABLES][MAX_PATTERN]int = {}
	output_mask: [MAX_VARIABLES][MAX_PATTERN]u64 = {}
	for variable := 0; variable < variable_count; variable += 1 { for state := 0; state < pattern_length; state += 1 {
		if kind[variable] == 0 {
			next := state
			for next > 0 && pattern[next] != terminal[variable] { next = failure[next-1] }
			if pattern[next] == terminal[variable] { next += 1 }
			if next == pattern_length { output_mask[variable][state] = 1; next = failure[pattern_length-1] }
			jump[variable][state] = next
		} else {
			left, right := first[variable], second[variable]
			middle := jump[left][state]
			jump[variable][state] = jump[right][middle]
			output_mask[variable][state] = output_mask[left][state] | (output_mask[right][middle] << variable_length[left])
		}
	} }
	state, offset := 0, 0
	end_offsets: u64 = 0
	for i := 0; i < factor_count; i += 1 {
		variable := factors[i]
		end_offsets |= output_mask[variable][state] << offset
		state = jump[variable][state]
		offset += variable_length[variable]
	}
	words: [1+MAX_TEXT]i64 = {}
	occurrences := 0
	for ending := 0; ending < text_length; ending += 1 {
		if ((end_offsets >> ending) & 1) != 0 {
			if ending+1 < pattern_length do return -1
			words[1+occurrences] = i64(ending+1-pattern_length)
			occurrences += 1
		}
	}
	words[0] = i64(occurrences)
	output_bytes := 8*(1+occurrences)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	for word := 0; word < 1+occurrences; word += 1 { store_i64_le(&staged[0], 8*word, words[word]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
