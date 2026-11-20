module egg_drop_max_floors_by_moves

const max_eggs = i64(32)
const max_moves = i64(32)

@[export: 'egg_drop_max_floors_by_moves']
pub fn egg_drop_max_floors_by_moves(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		eggs := input[0]
		moves := input[1]
		if eggs < 0 || eggs > max_eggs || moves < 0 || moves > max_moves { return -1 }
		mut covered := [33]i64{}
		for _ in 0 .. int(moves) {
			mut egg := int(eggs)
			for egg > 0 {
				covered[egg] += covered[egg - 1] + 1
				egg--
			}
		}
		return covered[int(eggs)]
	}
}
