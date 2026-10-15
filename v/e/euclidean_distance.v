module euclidean_distance

import math

const max_dimension = 128

@[export: 'euclidean_distance']
pub fn euclidean_distance(values &i64, length usize) f64 {
	if length < 1 { return -1.0e300 }
	dimension_value := unsafe { values[0] }
	if dimension_value < 0 || dimension_value > max_dimension { return -1.0e300 }
	dimension := int(dimension_value)
	if length != usize(1 + 2 * dimension) { return -1.0e300 }
	mut sum_of_squares := 0.0
	for i in 0 .. dimension {
		first := unsafe { values[1 + i] }
		second := unsafe { values[1 + dimension + i] }
		if first < -1000000 || first > 1000000 || second < -1000000 || second > 1000000 { return -1.0e300 }
		difference := f64(first) - f64(second)
		sum_of_squares += difference * difference
	}
	return math.sqrt(sum_of_squares)
}
