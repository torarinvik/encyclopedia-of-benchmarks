package egg_drop_max_floors_by_moves

import "core:c"

MAX_EGGS :: i64(32)
MAX_MOVES :: i64(32)

@(export, link_name="egg_drop_max_floors_by_moves")
egg_drop_max_floors_by_moves :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	eggs, moves := input[0], input[1]
	if eggs < 0 || eggs > MAX_EGGS || moves < 0 || moves > MAX_MOVES do return -1
	covered: [33]i64
	for egg := 0; egg <= 32; egg += 1 { covered[egg] = 0 }
	for move := i64(0); move < moves; move += 1 {
		for egg := eggs; egg > 0; egg -= 1 {
			covered[egg] += covered[egg - 1] + 1
		}
	}
	return covered[eggs]
}
