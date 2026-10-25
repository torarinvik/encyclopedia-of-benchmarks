package scimark2_sor

import "core:c"

@(export)
scimark2_sor :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 67 do return -1
	row_value := input[0]
	col_value := input[1]
	iteration_value := input[2]
	if row_value < 2 || row_value > 8 || col_value < 2 || col_value > 8 || iteration_value < 0 || iteration_value > 8 do return -1
	rows := int(row_value)
	cols := int(col_value)
	iterations := int(iteration_value)
	if length != c.size_t(3 + rows*cols) do return -1
	grid: [64]i64
	for i in 0..<rows*cols {
		value := input[3+i]
		if value < -1000 || value > 1000 do return -1
		grid[i] = value
	}
	for _ in 0..<iterations {
		for row := 1; row < rows-1; row += 1 {
			for col := 1; col < cols-1; col += 1 {
				index := row*cols+col
				neighbors := grid[index-cols]+grid[index+cols]+grid[index-1]+grid[index+1]
				numerator := 1250*neighbors-1000*grid[index]
				grid[index] = numerator/4000
			}
		}
	}
	checksum: i64 = 0
	for i in 0..<rows*cols { checksum += i64(i+1)*grid[i] }
	return checksum
}
