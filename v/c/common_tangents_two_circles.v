const max_coordinate = i64(100000)
const max_radius = i64(100000)

fn count_tangents(x1 i64, y1 i64, r1 i64, x2 i64, y2 i64, r2 i64) i64 {
	dx := x2 - x1
	dy := y2 - y1
	distance_squared := dx * dx + dy * dy
	signs := [2]i64{-1, 1}
	mut candidates := i64(0)
	for i in 0 .. 2 {
		for j in 0 .. 2 {
			difference := signs[j] * r2 - signs[i] * r1
			if distance_squared >= difference * difference { candidates++ }
		}
	}
	if r1 == 0 && r2 == 0 { return 1 }
	if r1 == 0 || r2 == 0 {
		radius := r1 + r2
		if distance_squared == radius * radius { return 1 }
		return candidates / 2
	}
	radius_sum := r1 + r2
	radius_difference := r1 - r2
	if distance_squared == radius_sum * radius_sum || distance_squared == radius_difference * radius_difference {
		candidates--
	}
	return candidates
}

@[export: 'common_tangents_two_circles']
pub fn common_tangents_two_circles(input &i64, length usize) i64 {
	if length != 6 { return -1 }
	unsafe {
		if input == nil { return -1 }
		x1, y1, r1 := input[0], input[1], input[2]
		x2, y2, r2 := input[3], input[4], input[5]
		if x1 < -max_coordinate || x1 > max_coordinate ||
			y1 < -max_coordinate || y1 > max_coordinate ||
			x2 < -max_coordinate || x2 > max_coordinate ||
			y2 < -max_coordinate || y2 > max_coordinate ||
			r1 < 0 || r1 > max_radius || r2 < 0 || r2 > max_radius ||
			(x1 == x2 && y1 == y2) { return -1 }
		return count_tangents(x1, y1, r1, x2, y2, r2)
	}
}
