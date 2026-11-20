module rsk_row_insertion

const max_n = 8
const invalid_result = i64(-9223372036854775807) - 1

@[export: 'rsk_row_insertion']
pub fn rsk_row_insertion(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_n + 2 { return invalid_result }
	unsafe {
		n_value := input[0]
		if n_value < 0 || n_value > max_n || length != usize(n_value + 1) { return invalid_result }
		n := int(n_value)
		mut seen := [max_n]bool{}
		for i in 0 .. n {
			value := input[i + 1]
			if value < 0 || value >= n_value || seen[int(value)] { return invalid_result }
			seen[int(value)] = true
		}
		if n == 0 { return 0 }

		mut p := [max_n * max_n]i64{}
		mut q := [max_n * max_n]i64{}
		mut row_lengths := [max_n]int{}
		mut row_count := 0
		for step in 1 .. n + 1 {
			mut value := input[step] + 1
			mut row := 0
			for {
				if row == row_count {
					p[row * max_n] = value
					q[row * max_n] = i64(step)
					row_lengths[row] = 1
					row_count++
					break
				}
				mut column := 0
				for column < row_lengths[row] && p[row * max_n + column] < value {
					column++
				}
				if column == row_lengths[row] {
					p[row * max_n + column] = value
					q[row * max_n + column] = i64(step)
					row_lengths[row]++
					break
				}
				bumped := p[row * max_n + column]
				p[row * max_n + column] = value
				value = bumped
				row++
			}
		}

		mut p_row := [max_n]i64{}
		mut q_row := [max_n]i64{}
		for row in 0 .. row_count {
			for column in 0 .. row_lengths[row] {
				p_row[int(p[row * max_n + column] - 1)] = i64(row)
				q_row[int(q[row * max_n + column] - 1)] = i64(row)
			}
		}
		mut code := n_value
		for label in 0 .. n {
			code = code * 9 + p_row[label] + 1
			code = code * 9 + q_row[label] + 1
		}
		return code
	}
}
