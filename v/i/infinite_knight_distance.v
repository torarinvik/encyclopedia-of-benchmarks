module infinite_knight_distance

const max_coordinate = i64(1000000000)

@[export: 'infinite_knight_distance']
pub fn infinite_knight_distance(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		dx := input[0]
		dy := input[1]
		if dx < -max_coordinate || dx > max_coordinate || dy < -max_coordinate || dy > max_coordinate {
			return -1
		}
		abs_x := if dx < 0 { -dx } else { dx }
		abs_y := if dy < 0 { -dy } else { dy }
		large := if abs_x > abs_y { abs_x } else { abs_y }
		small := if abs_x < abs_y { abs_x } else { abs_y }
		if large == 1 && small == 0 { return 3 }
		if large == 2 && small == 2 { return 4 }
		mut distance := (large + 1) / 2
		diagonal_bound := (large + small + 2) / 3
		if diagonal_bound > distance { distance = diagonal_bound }
		if (large + small - distance) % 2 != 0 { distance++ }
		return distance
	}
}
