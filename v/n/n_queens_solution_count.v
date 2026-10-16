module n_queens_solution_count

const max_n = 8

fn count_from(n int, column int, mut rows []bool, mut down []bool, mut up []bool) i64 {
	if column == n { return 1 }
	mut count := i64(0)
	for row in 0 .. n {
		d := row - column + n - 1
		u := row + column
		if !rows[row] && !down[d] && !up[u] {
			rows[row] = true; down[d] = true; up[u] = true
			count += count_from(n, column + 1, mut rows, mut down, mut up)
			rows[row] = false; down[d] = false; up[u] = false
		}
	}
	return count
}

@[export: 'n_queens_solution_count']
pub fn n_queens_solution_count(values &i64, length usize) i64 {
	if values == nil || length != 1 { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > max_n { return -1 }
		mut rows := []bool{len: max_n}
		mut down := []bool{len: 2 * max_n}
		mut up := []bool{len: 2 * max_n}
		return count_from(int(values[0]), 0, mut rows, mut down, mut up)
	}
}
