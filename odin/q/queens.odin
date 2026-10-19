package queens

import "core:c"

MAX_N :: 14
MAX_DIAGS :: 2 * MAX_N - 1
EMPTY_OWNER :: 101
MAX_OUTPUT_BYTES :: 80

Queens_State :: struct {
	n: int,
	queen: [MAX_N]int,
	file: [MAX_N]int,
	forward_diag: [MAX_DIAGS]int,
	backward_diag: [MAX_DIAGS]int,
	solutions: u64,
}

find_solutions :: proc(state: ^Queens_State, level: int) {
	if level == state^.n {
		state^.solutions += 1
		return
	}
	for file_index := 0; file_index < state^.n; file_index += 1 {
		forward := file_index + level
		backward := level - file_index + state^.n - 1
		if state^.file[file_index] >= level && state^.forward_diag[forward] >= level &&
			state^.backward_diag[backward] >= level {
			state^.queen[level] = file_index
			state^.file[file_index] = level
			state^.forward_diag[forward] = level
			state^.backward_diag[backward] = level
			find_solutions(state, level + 1)
			state^.file[file_index] = EMPTY_OWNER
			state^.forward_diag[forward] = EMPTY_OWNER
			state^.backward_diag[backward] = EMPTY_OWNER
		}
	}
}

append_text :: proc(output: [^]u8, position_input: int, text: string) -> int {
	position := position_input
	for index := 0; index < len(text); index += 1 {
		output[position] = text[index]
		position += 1
	}
	return position
}

append_unsigned :: proc(output: [^]u8, position_input: int, value_input: u64) -> int {
	position := position_input
	var reversed: [24]u8
	count := 0
	value := value_input
	for {
		reversed[count] = u8('0' + value % 10)
		count += 1
		value /= 10
		if value == 0 do break
	}
	for count > 0 {
		count -= 1
		output[position] = reversed[count]
		position += 1
	}
	return position
}

render_output :: proc(n: int, solutions: u64, output: [^]u8) -> int {
	position := append_unsigned(output, 0, u64(n))
	if n == 1 {
		position = append_text(output, position, " queen on a ")
	} else {
		position = append_text(output, position, " queens on a ")
	}
	position = append_unsigned(output, position, u64(n))
	output[position] = 'x'
	position += 1
	position = append_unsigned(output, position, u64(n))
	position = append_text(output, position, " board...\n")
	if solutions == 1 {
		position = append_text(output, position, "...there is 1 solution\n")
	} else {
		position = append_text(output, position, "...there are ")
		position = append_unsigned(output, position, solutions)
		position = append_text(output, position, " solutions\n")
	}
	return position
}

@(export)
queens :: proc "c" (n: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if n < 1 || n > i64(MAX_N) do return -1
	state := Queens_State{n = int(n)}
	for index := 0; index < MAX_N; index += 1 do state.file[index] = EMPTY_OWNER
	for index := 0; index < MAX_DIAGS; index += 1 {
		state.forward_diag[index] = EMPTY_OWNER
		state.backward_diag[index] = EMPTY_OWNER
	}
	find_solutions(&state, 0)
	var formatted: [MAX_OUTPUT_BYTES]u8
	required := render_output(state.n, state.solutions, &formatted[0])
	if output == nil || output_capacity < c.size_t(required) do return -2
	for index := 0; index < required; index += 1 do output[index] = formatted[index]
	return i64(required)
}
