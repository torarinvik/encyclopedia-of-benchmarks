package cherry_pickup_ii

import "core:c"

MAX_DIM :: 6
MAX_INPUT :: 39
STATES :: 36

@(export)
cherry_pickup_ii :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 6 || length > MAX_INPUT do return -1
	rows_value, columns_value := input[0], input[1]
	if rows_value < 2 || rows_value > MAX_DIM || columns_value < 2 || columns_value > MAX_DIM do return -1
	rows, columns := int(rows_value), int(columns_value)
	if length != c.size_t(2 + rows * columns) do return -1
	for i := 0; i < rows * columns; i += 1 {
		if input[2 + i] < 0 || input[2 + i] > 100 do return -1
	}
	previous: [STATES]i64
	current: [STATES]i64
	for i := 0; i < STATES; i += 1 { previous[i] = -1 }
	previous[columns - 1] = input[2] + input[2 + columns - 1]
	for row := 1; row < rows; row += 1 {
		for i := 0; i < STATES; i += 1 { current[i] = -1 }
		for left := 0; left < columns; left += 1 {
			for right := 0; right < columns; right += 1 {
				score := previous[left * columns + right]
				if score < 0 do continue
				for dl := -1; dl <= 1; dl += 1 {
					next_left := left + dl
					if next_left < 0 || next_left >= columns do continue
					for dr := -1; dr <= 1; dr += 1 {
						next_right := right + dr
						if next_right < 0 || next_right >= columns do continue
						candidate := score + input[2 + row * columns + next_left]
						if next_left != next_right do candidate += input[2 + row * columns + next_right]
						slot := next_left * columns + next_right
						if candidate > current[slot] do current[slot] = candidate
					}
				}
			}
		}
		for i := 0; i < STATES; i += 1 { previous[i] = current[i] }
	}
	answer := i64(-1)
	for left := 0; left < columns; left += 1 {
		for right := 0; right < columns; right += 1 {
			if previous[left * columns + right] > answer do answer = previous[left * columns + right]
		}
	}
	return answer
}
