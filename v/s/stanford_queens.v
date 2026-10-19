const min_runs = 1
const max_runs = 100
const solve_repetitions = 50
const max_output_bytes = 292

fn try_queens(row int, mut columns []bool, mut diagonal_sum []bool, mut diagonal_diff []bool, mut positions []int) bool {
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
	mut a := []bool{len: 9}
	mut b := []bool{len: 17}
	mut c := []bool{len: 15}
	mut x := []int{len: 9}
	for i in 1 .. 9 { a[i] = true }
	for i in 2 .. 17 { b[i] = true }
	for i in 0 .. 15 { c[i] = true }
	return try_queens(1, mut a, mut b, mut c, mut x)
}

fn append_text(mut buffer []u8, mut used int, text string) {
	for byte in text.bytes() { buffer[used] = byte; used++ }
}

fn append_integer(mut buffer []u8, mut used int, value int) {
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
}

@[export: 'stanford_queens']
pub fn stanford_queens(runs i64, mut output &u8, output_capacity usize) i64 {
	if runs < min_runs || runs > max_runs { return -1 }
	if unsafe { output == nil } { return -2 }
	mut staged := [max_output_bytes]u8{}
	mut used := 0
	for run in 0 .. int(runs) {
		for _ in 0 .. solve_repetitions {
			if !doit() { append_text(mut staged[..], mut used, ' Error in Queens.\n') }
		}
		append_integer(mut staged[..], mut used, run + 1)
		append_text(mut staged[..], mut used, '\n')
	}
	if output_capacity < usize(used) { return -2 }
	unsafe { for index in 0 .. used { output[index] = staged[index] } }
	return i64(used)
}
