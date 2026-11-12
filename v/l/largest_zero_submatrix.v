module largest_zero_submatrix

const max_rows = 16
const max_columns = 16

@[export: 'largest_zero_submatrix']
pub fn largest_zero_submatrix(input &i64, length usize) i64 {
	if length < 2 || length > 259 || unsafe { input == nil } { return -1 }
	unsafe {
		rows_value, columns_value := input[0], input[1]
		if rows_value < 1 || rows_value > max_rows || columns_value < 1 || columns_value > max_columns { return -1 }
		rows, columns := int(rows_value), int(columns_value)
		if int(length) != 2 + rows * columns { return -1 }
		for index in 2 .. int(length) {
			if input[index] != 0 && input[index] != 1 { return -1 }
		}
		mut last_one := [max_columns]i64{}
		mut left := [max_columns]i64{}
		mut right := [max_columns]i64{}
		mut stack := [max_columns]int{}
		for column in 0 .. columns { last_one[column] = -1 }
		mut best := i64(0)
		for row in 0 .. rows {
			for column in 0 .. columns {
				if input[2 + row * columns + column] == 1 { last_one[column] = i64(row) }
			}
			mut top := 0
			for column in 0 .. columns {
				for top > 0 && last_one[stack[top - 1]] <= last_one[column] { top-- }
				left[column] = if top == 0 { -1 } else { i64(stack[top - 1]) }
				stack[top] = column
				top++
			}
			top = 0
			mut cursor := columns
			for cursor > 0 {
				column := cursor - 1
				for top > 0 && last_one[stack[top - 1]] <= last_one[column] { top-- }
				right[column] = if top == 0 { i64(columns) } else { i64(stack[top - 1]) }
				stack[top] = column
				top++
				cursor--
			}
			for column in 0 .. columns {
				height := i64(row) - last_one[column]
				width := right[column] - left[column] - 1
				area := height * width
				if area > best { best = area }
			}
		}
		return best
	}
}
