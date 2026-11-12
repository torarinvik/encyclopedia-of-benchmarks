package hirschberg_lcs

import "core:c"

MAX_SEQUENCE_LENGTH :: 64
MAX_INPUT_LENGTH :: 132

Hirschberg_State :: struct {
	forward: [MAX_SEQUENCE_LENGTH + 1]i32,
	backward: [MAX_SEQUENCE_LENGTH + 1]i32,
	result: [MAX_SEQUENCE_LENGTH]u8,
	result_length: int,
}

lcs_row :: proc(input: [^]i64, a_base, a0, a1, b_base, b0, b1: int,
		reverse_a, reverse_b: bool, row: ^[MAX_SEQUENCE_LENGTH + 1]i32) {
	width := b1 - b0
	for j := 0; j <= width; j += 1 { row[j] = 0 }
	for i := 0; i < a1 - a0; i += 1 {
		av := input[a_base + (if reverse_a do a1 - 1 - i else a0 + i)]
		diagonal: i32 = 0
		for j := 1; j <= width; j += 1 {
			above := row[j]
			bv := input[b_base + (if reverse_b do b1 - j else b0 + j - 1)]
			if av == bv { row[j] = diagonal + 1 }
			else if row[j - 1] > row[j] { row[j] = row[j - 1] }
			diagonal = above
		}
	}
}

recover_lcs :: proc(input: [^]i64, a_base, a0, a1, b_base, b0, b1: int,
		state: ^Hirschberg_State) {
	a_length := a1 - a0
	b_length := b1 - b0
	if a_length == 0 || b_length == 0 { return }
	if a_length == 1 {
		target := input[a_base + a0]
		for j := b0; j < b1; j += 1 {
			if input[b_base + j] == target {
				state.result[state.result_length] = u8(target)
				state.result_length += 1
				return
			}
		}
		return
	}

	middle := a0 + a_length / 2
	lcs_row(input, a_base, a0, middle, b_base, b0, b1, false, false, &state.forward)
	lcs_row(input, a_base, middle, a1, b_base, b0, b1, true, true, &state.backward)
	split := 0
	best_score: i32 = -1
	for j := 0; j <= b_length; j += 1 {
		score := state.forward[j] + state.backward[b_length - j]
		if score > best_score { best_score = score; split = j }
	}
	recover_lcs(input, a_base, a0, middle, b_base, b0, b0 + split, state)
	recover_lcs(input, a_base, middle, a1, b_base, b0 + split, b1, state)
}

@(export, link_name="hirschberg_lcs")
hirschberg_lcs :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 0 || input[0] > MAX_SEQUENCE_LENGTH || input[1] < 0 || input[1] > MAX_SEQUENCE_LENGTH do return -1
	first_length := int(input[0])
	second_length := int(input[1])
	if length != c.size_t(2 + first_length + second_length) do return -1
	for i := 0; i < first_length + second_length; i += 1 {
		if input[2 + i] < 0 || input[2 + i] > 127 do return -1
	}

	state: Hirschberg_State
	a_base := 2
	b_base := 2 + first_length
	a_length := first_length
	b_length := second_length
	if a_length < b_length {
		a_base = 2 + first_length
		b_base = 2
		a_length = second_length
		b_length = first_length
	}
	recover_lcs(input, a_base, 0, a_length, b_base, 0, b_length, &state)
	if output == nil || capacity < c.size_t(state.result_length) do return -2
	for i := 0; i < state.result_length; i += 1 { output[i] = state.result[i] }
	return i64(state.result_length)
}
