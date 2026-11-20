module cherry_pickup_ii

const max_dim = 6
const max_input = 39
const states = 36

@[export: 'cherry_pickup_ii']
pub fn cherry_pickup_ii(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 6 || length > max_input { return -1 }
	rows_value, columns_value := input[0], input[1]
	if rows_value < 2 || rows_value > max_dim || columns_value < 2 || columns_value > max_dim { return -1 }
	rows, columns := int(rows_value), int(columns_value)
	if length != usize(2 + rows * columns) { return -1 }
	for i in 0 .. rows * columns { if input[2 + i] < 0 || input[2 + i] > 100 { return -1 } }
	mut previous := []i64{len: states, init: -1}
	mut current := []i64{len: states, init: -1}
	previous[columns - 1] = input[2] + input[2 + columns - 1]
	for row in 1 .. rows {
		for i in 0 .. states { current[i] = -1 }
		for left in 0 .. columns {
			for right in 0 .. columns {
				score := previous[left * columns + right]
				if score < 0 { continue }
				for dl in -1 .. 2 {
					next_left := left + dl
					if next_left < 0 || next_left >= columns { continue }
					for dr in -1 .. 2 {
						next_right := right + dr
						if next_right < 0 || next_right >= columns { continue }
						mut candidate := score + input[2 + row * columns + next_left]
						if next_left != next_right { candidate += input[2 + row * columns + next_right] }
						slot := next_left * columns + next_right
						if candidate > current[slot] { current[slot] = candidate }
					}
				}
			}
		}
		for i in 0 .. states { previous[i] = current[i] }
	}
	mut answer := i64(-1)
	for left in 0 .. columns {
		for right in 0 .. columns { answer = max(answer, previous[left * columns + right]) }
	}
	return answer
}
