module main

const max_rows = 8
const max_cols = 8
const max_input = 67

@[export: 'scimark2_sor']
pub fn scimark2_sor(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input { return -1 }
	row_value := unsafe { input[0] }
	col_value := unsafe { input[1] }
	iteration_value := unsafe { input[2] }
	if row_value < 2 || row_value > max_rows || col_value < 2 || col_value > max_cols || iteration_value < 0 || iteration_value > 8 { return -1 }
	rows := int(row_value)
	cols := int(col_value)
	iterations := int(iteration_value)
	if length != usize(3 + rows * cols) { return -1 }
	mut grid := [64]i64{}
	for i in 0 .. rows * cols {
		value := unsafe { input[3 + i] }
		if value < -1000 || value > 1000 { return -1 }
		grid[i] = value
	}
	for _ in 0 .. iterations {
		for row := 1; row < rows - 1; row++ {
			for col := 1; col < cols - 1; col++ {
				index := row * cols + col
				neighbors := grid[index - cols] + grid[index + cols] + grid[index - 1] + grid[index + 1]
				numerator := i64(1250) * neighbors - i64(1000) * grid[index]
				grid[index] = numerator / i64(4000)
			}
		}
	}
	mut checksum := i64(0)
	for i in 0 .. rows * cols { checksum += i64(i + 1) * grid[i] }
	return checksum
}
