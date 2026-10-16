module egg_dropping_puzzle

const MaxEggs = 8
const MaxFloors = 32

@[export: 'egg_dropping_puzzle']
pub fn egg_dropping_puzzle(input &i64, length usize) i64 {
	if length != 2 || unsafe { input == nil } { return -1 }
	eggs_value := unsafe { input[0] }
	floors_value := unsafe { input[1] }
	if eggs_value < 1 || eggs_value > MaxEggs || floors_value < 1 || floors_value > MaxFloors { return -1 }

	eggs := int(eggs_value)
	floors := int(floors_value)
	mut dp := [MaxEggs + 1][MaxFloors + 1]i64{}
	for egg in 1 .. eggs + 1 { dp[egg][1] = 1 }
	for floor_count in 1 .. floors + 1 { dp[1][floor_count] = i64(floor_count) }

	for egg in 2 .. eggs + 1 {
		for floor_count in 2 .. floors + 1 {
			mut best := i64(MaxFloors + 1)
			for drop_floor in 1 .. floor_count + 1 {
				broken := dp[egg - 1][drop_floor - 1]
				survives := dp[egg][floor_count - drop_floor]
				worst := if broken > survives { broken } else { survives }
				candidate := worst + 1
				if candidate < best { best = candidate }
			}
			dp[egg][floor_count] = best
		}
	}
	return dp[eggs][floors]
}
