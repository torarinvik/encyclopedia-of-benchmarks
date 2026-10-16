package egg_dropping

import "core:c"

Invalid_Result :: i64(-9223372036854775807 - 1)
Max_Eggs :: 12
Max_Floors :: 128
Floor_Width :: Max_Floors + 1

@(export)
egg_dropping :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return Invalid_Result
	if input[0] < 1 || input[0] > i64(Max_Eggs) || input[1] < 1 || input[1] > i64(Max_Floors) do return Invalid_Result

	eggs := int(input[0])
	floors := int(input[1])
	dp: [ (Max_Eggs + 1) * Floor_Width ]i64

	for egg := 1; egg <= eggs; egg += 1 { dp[egg * Floor_Width + 1] = 1 }
	for floor := 1; floor <= floors; floor += 1 { dp[Floor_Width + floor] = i64(floor) }
	for egg := 2; egg <= eggs; egg += 1 {
		for floor := 2; floor <= floors; floor += 1 {
			best := i64(9223372036854775807)
			for drop := 1; drop <= floor; drop += 1 {
				breaks := dp[(egg - 1) * Floor_Width + drop - 1]
				survives := dp[egg * Floor_Width + floor - drop]
				worst := 1 + max(breaks, survives)
				if worst < best do best = worst
			}
			dp[egg * Floor_Width + floor] = best
		}
	}
	return dp[eggs * Floor_Width + floors]
}
