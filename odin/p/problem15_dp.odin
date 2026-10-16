package problem15_dp

@(export)
problem15_dp :: proc "c" (grid_size: i64) -> i64 {
	if grid_size < 0 || grid_size > 20 do return -1
	counts: [21][21]i64
	for row in 0..21 {
		for column in 0..21 {
			counts[row][column] = 1
		}
	}
	for row in 1..u64(grid_size + 1) {
		for column in 1..u64(grid_size + 1) {
			counts[row][column] = counts[row - 1][column] + counts[row][column - 1]
		}
	}
	return counts[u64(grid_size)][u64(grid_size)]
}
