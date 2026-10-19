module queens

const max_n = 14
const max_diags = 2 * max_n - 1
const empty_owner = 101
const max_output_bytes = 80

struct QueensState {
	n int
	queen [max_n]int
	file [max_n]int
	forward_diag [max_diags]int
	backward_diag [max_diags]int
	solutions u64
}

fn find_solutions(mut state QueensState, level int) {
	if level == state.n {
		state.solutions++
		return
	}
	for file_index in 0 .. state.n {
		forward := file_index + level
		backward := level - file_index + state.n - 1
		if state.file[file_index] >= level && state.forward_diag[forward] >= level &&
			state.backward_diag[backward] >= level {
			state.queen[level] = file_index
			state.file[file_index] = level
			state.forward_diag[forward] = level
			state.backward_diag[backward] = level
			find_solutions(mut state, level + 1)
			state.file[file_index] = empty_owner
			state.forward_diag[forward] = empty_owner
			state.backward_diag[backward] = empty_owner
		}
	}
}

fn append_text(mut output &u8, position_input int, text string) int {
	mut position := position_input
	for index in 0 .. text.len {
		unsafe { output[position] = text[index] }
		position++
	}
	return position
}

fn append_unsigned(mut output &u8, position_input int, value_input u64) int {
	mut position := position_input
	mut reversed := [24]u8{}
	mut count := 0
	mut value := value_input
	for {
		reversed[count] = u8(48 + value % 10)
		count++
		value /= 10
		if value == 0 { break }
	}
	for count > 0 {
		count--
		unsafe { output[position] = reversed[count] }
		position++
	}
	return position
}

fn render_output(n int, solutions u64, mut output &u8) int {
	mut position := append_unsigned(mut output, 0, u64(n))
	if n == 1 {
		position = append_text(mut output, position, " queen on a ")
	} else {
		position = append_text(mut output, position, " queens on a ")
	}
	position = append_unsigned(mut output, position, u64(n))
	unsafe { output[position] = `x` }
	position++
	position = append_unsigned(mut output, position, u64(n))
	position = append_text(mut output, position, " board...\n")
	if solutions == 1 {
		position = append_text(mut output, position, "...there is 1 solution\n")
	} else {
		position = append_text(mut output, position, "...there are ")
		position = append_unsigned(mut output, position, solutions)
		position = append_text(mut output, position, " solutions\n")
	}
	return position
}

@[export: 'queens']
pub fn queens(n i64, mut output &u8, output_capacity usize) i64 {
	if n < 1 || n > i64(max_n) { return -1 }
	mut state := QueensState{n: int(n)}
	for index in 0 .. max_n { state.file[index] = empty_owner }
	for index in 0 .. max_diags {
		state.forward_diag[index] = empty_owner
		state.backward_diag[index] = empty_owner
	}
	find_solutions(mut state, 0)

	mut formatted := [max_output_bytes]u8{}
	mut formatted_pointer := &formatted[0]
	required := render_output(int(n), state.solutions, mut formatted_pointer)
	unsafe {
		if output == nil || output_capacity < usize(required) { return -2 }
		for index in 0 .. required { output[index] = formatted[index] }
	}
	return i64(required)
}
