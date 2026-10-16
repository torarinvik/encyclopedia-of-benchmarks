module problem15_dp

@[export: 'problem15_dp']
pub fn problem15_dp(grid_size i64) i64 {
	if grid_size < 0 || grid_size > 20 { return -1 }
	mut counts := [21][21]i64{}
	for row in 0 .. 21 {
		for column in 0 .. 21 {
			counts[row][column] = 1
		}
	}
	for row in 1 .. int(grid_size + 1) {
		for column in 1 .. int(grid_size + 1) {
			counts[row][column] = counts[row - 1][column] + counts[row][column - 1]
		}
	}
	return counts[int(grid_size)][int(grid_size)]
}
