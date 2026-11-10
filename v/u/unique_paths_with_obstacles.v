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
		if length != usize(2 + rows * columns) { return -1 }

		mut paths := [max_columns]u64{init: 0}
		paths[0] = 1
		mut cells_seen := u64(0)
		mut left := u64(0)
		mut index := 2
		for index < int(length) {
			left = 0
			for column in 0 .. columns {
				obstacle := u64(input[index])
				cells_seen |= obstacle
				left = if obstacle == 0 { left + paths[column] } else { u64(0) }
				paths[column] = left
				index++
			}
		}
		if cells_seen > 1 { return -1 }
		return i64(left)
	}
}
