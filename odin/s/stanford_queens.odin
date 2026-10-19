package stanford_queens

import "core:c"

MIN_RUNS :: i64(1)
MAX_RUNS :: i64(100)
SOLVE_REPETITIONS :: 50
MAX_OUTPUT_BYTES :: 292

try_queens :: proc(row: int, columns: ^[9]bool, diagonal_sum: ^[17]bool,
		diagonal_diff: ^[15]bool, positions: ^[9]int) -> bool {
	j := 0
	found := false
	for !found && j != 8 {
		j += 1
		found = false
		if columns[j] && diagonal_sum[row+j] && diagonal_diff[row-j+7] {
			positions[row] = j
			columns[j] = false
			diagonal_sum[row+j] = false
			diagonal_diff[row-j+7] = false
			if row < 8 {
				found = try_queens(row+1, columns, diagonal_sum, diagonal_diff, positions)
				if !found {
					columns[j] = true
					diagonal_sum[row+j] = true
					diagonal_diff[row-j+7] = true
				}
			} else {
				found = true
			}
		}
	}
	return found
}

doit :: proc() -> bool {
	a: [9]bool = {}
	b: [17]bool = {}
	cells: [15]bool = {}
	x: [9]int = {}
	for i := -7; i <= 16; i += 1 {
		if i >= 1 && i <= 8 { a[i] = true }
		if i >= 2 { b[i] = true }
		if i <= 7 { cells[i+7] = true }
	}
	return try_queens(1, &a, &b, &cells, &x)
}

append_text :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, text: string) {
	for byte in transmute([]u8)text { buffer[used^] = byte; used^ += 1 }
}

append_integer :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, value: int) {
	remaining := value
	var reversed: [12]u8
	count := 0
	for { reversed[count] = u8('0') + u8(remaining%10); count += 1; remaining /= 10; if remaining == 0 do break }
	for count > 0 { count -= 1; buffer[used^] = reversed[count]; used^ += 1 }
}

@(export)
stanford_queens :: proc "c" (runs: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if runs < MIN_RUNS || runs > MAX_RUNS do return -1
	if output == nil do return -2
	var staged: [MAX_OUTPUT_BYTES]u8
	used := 0
	for run := 0; run < int(runs); run += 1 {
		for repetition := 0; repetition < SOLVE_REPETITIONS; repetition += 1 {
			if !doit() { append_text(&staged, &used, " Error in Queens.\n") }
		}
		append_integer(&staged, &used, run+1)
		append_text(&staged, &used, "\n")
	}
	if output_capacity < c.size_t(used) do return -2
	for index := 0; index < used; index += 1 { output[index] = staged[index] }
	return i64(used)
}
