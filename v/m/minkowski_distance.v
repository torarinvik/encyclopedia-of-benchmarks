module minkowski_distance

import math

const max_n = i64(8)
const max_p = i64(6)
const invalid_result = -1.0e300

@[export: 'minkowski_distance']
pub fn minkowski_distance(packed &i64, length usize) f64 {
	if length < 2 || length > 18 { return invalid_result }
	n := unsafe { packed[0] }
	p := unsafe { packed[1] }
	if n < 0 || n > max_n || p < 3 || p > max_p || length != usize(2 + 2 * n) { return invalid_result }
	for index in 0 .. int(n) {
		if unsafe { packed[2 + index] } < -100 || unsafe { packed[2 + index] } > 100 || unsafe { packed[2 + int(n) + index] } < -100 || unsafe { packed[2 + int(n) + index] } > 100 { return invalid_result }
	}
	mut total := i64(0)
	for index in 0 .. int(n) {
		mut difference := unsafe { packed[2 + index] - packed[2 + int(n) + index] }
		if difference < 0 { difference = -difference }
		mut term := i64(1)
		for _ in 0 .. int(p) { term *= difference }
		total += term
	}
	return math.pow(f64(total), 1.0 / f64(p))
}
