module problem44

import math

fn is_pentagonal(value i64) bool {
	if value < 1 { return false }
	discriminant := 24 * value + 1
	root := i64(math.sqrt(f64(discriminant)))
	return root * root == discriminant && (root + 1) % 6 == 0
}

@[export: 'problem44']
pub fn problem44(limit i64) i64 {
	if limit < 1 || limit > 5000 { return -1 }
	for i := i64(1); i < limit; i++ {
		first := i * (3 * i - 1) / 2
		for j := i; j < limit; j++ {
			second := j * (3 * j - 1) / 2
			difference := second - first
			if is_pentagonal(first + second) && is_pentagonal(difference) { return difference }
		}
	}
	return -1
}
