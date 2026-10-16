module problem18

const max_rows = 15
const max_values = max_rows * (max_rows + 1) / 2

@[export: 'problem18']
pub fn problem18(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_values + 1 { return -1 }
	rows := unsafe { input[0] }
	if rows < 1 || rows > max_rows || int(length) != int(rows * (rows + 1) / 2) + 1 { return -1 }
	mut best := [max_values]i64{}
	value_count := int(length) - 1
	for index in 0 .. value_count {
		value := unsafe { input[index + 1] }
		if value < 0 || value > 1_000_000 { return -1 }
		best[index] = value
	}
	mut row := rows - 1
	for row > 0 {
		parent_start := int((row - 1) * row / 2)
		child_start := int(row * (row + 1) / 2)
		for column in 0 .. int(row) {
			parent := parent_start + column
			child := child_start + column
			left := best[child]
			right := best[child + 1]
			best[parent] += if left > right { left } else { right }
		}
		row--
	}
	return best[0]
}
