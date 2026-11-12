module hirschberg_lcs

const max_sequence_length = 64
const max_input_length = 132

struct HirschbergState {
mut:
	forward [max_sequence_length + 1]i32
	backward [max_sequence_length + 1]i32
	result [max_sequence_length]u8
	result_length int
}

fn lcs_row(input &i64, a_base int, a0 int, a1 int, b_base int, b0 int, b1 int,
	reverse_a bool, reverse_b bool, mut row [max_sequence_length + 1]i32) {
	width := b1 - b0
	for j in 0 .. width + 1 { row[j] = 0 }
	for i in 0 .. a1 - a0 {
		av := unsafe { input[a_base + (if reverse_a { a1 - 1 - i } else { a0 + i })] }
		mut diagonal := i32(0)
		for j in 1 .. width + 1 {
			above := row[j]
			bv := unsafe { input[b_base + (if reverse_b { b1 - j } else { b0 + j - 1 })] }
			if av == bv { row[j] = diagonal + 1 }
			else if row[j - 1] > row[j] { row[j] = row[j - 1] }
			diagonal = above
		}
	}
}

fn recover_lcs(input &i64, a_base int, a0 int, a1 int, b_base int, b0 int, b1 int,
	mut state HirschbergState) {
	a_length := a1 - a0
	b_length := b1 - b0
	if a_length == 0 || b_length == 0 { return }
	if a_length == 1 {
		target := unsafe { input[a_base + a0] }
		for j in b0 .. b1 {
			if unsafe { input[b_base + j] } == target {
				state.result[state.result_length] = u8(target)
				state.result_length++
				return
			}
		}
		return
	}

	middle := a0 + a_length / 2
	lcs_row(input, a_base, a0, middle, b_base, b0, b1, false, false, mut state.forward)
	lcs_row(input, a_base, middle, a1, b_base, b0, b1, true, true, mut state.backward)
	mut split := 0
	mut best_score := i32(-1)
	for j in 0 .. b_length + 1 {
		score := state.forward[j] + state.backward[b_length - j]
		if score > best_score { best_score = score; split = j }
	}
	recover_lcs(input, a_base, a0, middle, b_base, b0, b0 + split, mut state)
	recover_lcs(input, a_base, middle, a1, b_base, b0 + split, b1, mut state)
}

@[export: 'hirschberg_lcs']
pub fn hirschberg_lcs(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		if input[0] < 0 || input[0] > max_sequence_length || input[1] < 0 || input[1] > max_sequence_length { return -1 }
		first_length := int(input[0])
		second_length := int(input[1])
		if length != 2 + first_length + second_length { return -1 }
		for i in 0 .. first_length + second_length {
			if input[2 + i] < 0 || input[2 + i] > 127 { return -1 }
		}

		mut state := HirschbergState{}
		mut a_base := 2
		mut b_base := 2 + first_length
		mut a_length := first_length
		mut b_length := second_length
		if a_length < b_length {
			a_base = 2 + first_length
			b_base = 2
			a_length = second_length
			b_length = first_length
		}
		recover_lcs(input, a_base, 0, a_length, b_base, 0, b_length, mut state)
		if output == nil || capacity < usize(state.result_length) { return -2 }
		for i in 0 .. state.result_length { output[i] = state.result[i] }
		return i64(state.result_length)
	}
}
