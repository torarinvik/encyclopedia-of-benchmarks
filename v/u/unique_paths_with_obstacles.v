module unique_paths_with_obstacles

const max_rows = 20
const max_columns = 20

// Count right/down paths through a packed obstacle grid.
@[export: 'unique_paths_with_obstacles']
pub fn unique_paths_with_obstacles(input &i64, length usize) i64 {
	if length < 2 { return -1 }
	unsafe {
		rows_value := input[0]
		columns_value := input[1]
		if rows_value < 1 || rows_value > max_rows ||
			columns_value < 1 || columns_value > max_columns { return -1 }
		rows := int(rows_value)
		columns := int(columns_value)
		if int(length) != 2 + rows * columns { return -1 }
		for index in 2 .. int(length) {
			if input[index] != 0 && input[index] != 1 { return -1 }
		}

		mut paths := [max_columns]i64{init: 0}
		paths[0] = 1
		for row in 0 .. rows {
			for column in 0 .. columns {
				obstacle := input[2 + row * columns + column]
				if obstacle == 1 { paths[column] = 0 }
				else if column > 0 { paths[column] += paths[column - 1] }
			}
		}
		return paths[columns - 1]
	}
}
