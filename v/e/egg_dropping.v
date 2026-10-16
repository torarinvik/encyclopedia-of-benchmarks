module egg_dropping

const invalid_result = i64(-9223372036854775807 - 1)
const max_eggs = 12
const max_floors = 128
const floor_width = max_floors + 1

@[export: 'egg_dropping']
pub fn egg_dropping(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 2 { return invalid_result }
	if unsafe { input[0] < 1 || input[0] > i64(max_eggs) || input[1] < 1 || input[1] > i64(max_floors) } {
		return invalid_result
	}

	eggs := int(unsafe { input[0] })
	floors := int(unsafe { input[1] })
	mut dp := [((max_eggs + 1) * floor_width)]i64{}

	for egg in 1 .. eggs + 1 { dp[egg * floor_width + 1] = 1 }
	for floor in 1 .. floors + 1 { dp[floor_width + floor] = i64(floor) }
	for egg in 2 .. eggs + 1 {
		for floor in 2 .. floors + 1 {
			mut best := i64(9223372036854775807)
			for drop in 1 .. floor + 1 {
				breaks := dp[(egg - 1) * floor_width + drop - 1]
				survives := dp[egg * floor_width + floor - drop]
				worst := i64(1) + if breaks > survives { breaks } else { survives }
				if worst < best { best = worst }
			}
			dp[egg * floor_width + floor] = best
		}
	}
	return dp[eggs * floor_width + floors]
}
