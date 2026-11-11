const min_runs = 1
const max_runs = 100
const solve_repetitions = 50
const max_output_bytes = 292

fn try_queens(row int, mut columns [9]bool, mut diagonal_sum [17]bool, mut diagonal_diff [15]bool, mut positions [9]int) bool {
	mut j := 0
	mut found := false
	for !found && j != 8 {
		j++
		found = false
		if columns[j] && diagonal_sum[row + j] && diagonal_diff[row - j + 7] {
			positions[row] = j
			columns[j] = false
			diagonal_sum[row + j] = false
			diagonal_diff[row - j + 7] = false
			if row < 8 {
				found = try_queens(row + 1, mut columns, mut diagonal_sum, mut diagonal_diff, mut positions)
				if !found {
					columns[j] = true
					diagonal_sum[row + j] = true
					diagonal_diff[row - j + 7] = true
				}
			} else {
				found = true
			}
		}
	}
	return found
}

fn doit() bool {
	mut a := [9]bool{}
	mut b := [17]bool{}
	mut c := [15]bool{}
	mut x := [9]int{}
	for i in 1 .. 9 { a[i] = true }
	for i in 2 .. 17 { b[i] = true }
	for i in 0 .. 15 { c[i] = true }
	return try_queens(1, mut a, mut b, mut c, mut x)
}

fn append_text(mut buffer [max_output_bytes]u8, start int, text string) int {
	mut used := start
	for index in 0 .. text.len { buffer[used] = text[index]; used++ }
	return used
}

fn append_integer(mut buffer [max_output_bytes]u8, start int, value int) int {
	mut used := start
	mut remaining := value
	mut reverse := [12]u8{}
	mut count := 0
	for {
		reverse[count] = u8(48 + remaining % 10)
		count++
		remaining /= 10
		if remaining == 0 { break }
	}
	for count > 0 { count--; buffer[used] = reverse[count]; used++ }
	return used
}

@[export: 'stanford_queens']
pub fn stanford_queens(runs i64, output &u8, output_capacity usize) i64 {
	if runs < min_runs || runs > max_runs { return -1 }
	if unsafe { output == nil } { return -2 }
	mut staged := [max_output_bytes]u8{}
	mut used := 0
	for run in 0 .. int(runs) {
		for _ in 0 .. solve_repetitions {
			if !doit() { used = append_text(mut staged, used, ' Error in Queens.\n') }
		}
		used = append_integer(mut staged, used, run + 1)
		used = append_text(mut staged, used, '\n')
	}
	if output_capacity < usize(used) { return -2 }
	unsafe { for index in 0 .. used { output[index] = staged[index] } }
	return i64(used)
}
