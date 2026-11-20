module brownian_tree_diffusion_limited_aggregation

const side = 33
const max_points = 17
const golden = u64(0x9e3779b97f4a7c15)
const multiplier = u64(0x2545f4914f6cdd1d)

fn dla_next(mut state &u64) u64 {
	state ^= state >> 12
	state ^= state << 25
	state ^= state >> 27
	return state * multiplier
}

fn dla_touches(occupied &u8, x int, y int) bool {
	unsafe {
		at := y * side + x
		return occupied[at - 1] != 0 || occupied[at - side] != 0 ||
			occupied[at + 1] != 0 || occupied[at + side] != 0
	}
}

fn dla_store_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'brownian_tree_diffusion_limited_aggregation']
pub fn brownian_tree_diffusion_limited_aggregation(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		attempts_value, seed_value, steps_value := input[0], input[1], input[2]
		if attempts_value < 0 || attempts_value > 16 || seed_value < 1 ||
			steps_value < 1 || steps_value > 512 { return -1 }

		mut occupied := [side * side]u8{}
		mut point_x := [max_points]i32{}
		mut point_y := [max_points]i32{}
		point_x[0] = 16
		point_y[0] = 16
		mut point_count := 1
		occupied[16 * side + 16] = 1

		for attempt in 0 .. int(attempts_value) {
			mut state := u64(seed_value) ^ (golden * u64(attempt + 1))
			if state == 0 { state = multiplier }
			side_draw := dla_next(mut state)
			position_draw := dla_next(mut state)
			launch_side := int(side_draw % 4)
			position := 1 + int(position_draw % 31)
			mut x, mut y := position, position
			if launch_side == 0 { y = 1 }
			else if launch_side == 1 { x = 31 }
			else if launch_side == 2 { y = 31 }
			else { x = 1 }

			mut at := y * side + x
			if occupied[at] != 0 { continue }
			if dla_touches(&occupied[0], x, y) {
				occupied[at] = 1
				point_x[point_count] = i32(x)
				point_y[point_count] = i32(y)
				point_count++
				continue
			}
			for _ in 0 .. int(steps_value) {
				direction := int(dla_next(mut state) % 4)
				if direction == 0 { x-- }
				else if direction == 1 { y-- }
				else if direction == 2 { x++ }
				else { y++ }
				if x == 0 || x == 32 || y == 0 || y == 32 { break }
				at = y * side + x
				if dla_touches(&occupied[0], x, y) {
					occupied[at] = 1
					point_x[point_count] = i32(x)
					point_y[point_count] = i32(y)
					point_count++
					break
				}
			}
		}

		required := (1 + 2 * point_count) * 8
		if output == nil || capacity < usize(required) { return -2 }
		dla_store_i64(mut output, 0, i64(point_count))
		for point in 0 .. point_count {
			dla_store_i64(mut output, (1 + 2 * point) * 8, i64(point_x[point]))
			dla_store_i64(mut output, (2 + 2 * point) * 8, i64(point_y[point]))
		}
		return i64(required)
	}
}
