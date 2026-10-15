module distance_between_two_points

import math

const max_coordinate = i64(1_000_000)
const invalid_result = -1.0e300

@[export: 'distance_between_two_points']
pub fn distance_between_two_points(values &i64, length usize) f64 {
	if length != 4 { return invalid_result }
	for index in 0 .. 4 {
		if values[index] < -max_coordinate || values[index] > max_coordinate { return invalid_result }
	}
	dx := f64(values[2] - values[0])
	dy := f64(values[3] - values[1])
	return math.sqrt(dx * dx + dy * dy)
}
