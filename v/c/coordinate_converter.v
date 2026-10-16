module coordinate_converter

import math

const invalid_result = -1.0e300
const coordinate_limit = 1_000_000.0
const angle_limit_degrees = 36_000.0
const degrees_per_radian = 57.2957795130823208768
const radians_per_degree = 0.0174532925199432957692

@[export: 'coordinate_converter']
pub fn coordinate_converter(first f64, second f64, component f64) f64 {
	if component == 0.0 || component == 1.0 {
		if first != first || second != second || first < -coordinate_limit || first > coordinate_limit ||
			second < -coordinate_limit || second > coordinate_limit { return invalid_result }
		if component == 0.0 { return math.sqrt(first * first + second * second) }
		return math.atan2(second, first) * degrees_per_radian
	}
	if component == 2.0 || component == 3.0 {
		if first != first || second != second || first < 0.0 || first > coordinate_limit ||
			second < -angle_limit_degrees || second > angle_limit_degrees { return invalid_result }
		radians := second * radians_per_degree
		if component == 2.0 { return first * math.cos(radians) }
		return first * math.sin(radians)
	}
	return invalid_result
}
