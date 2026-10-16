module problem99

import math

const max_pair_count = 1000
const max_base = i64(1_000_000)
const max_exponent = i64(1_200_000)

@[export: 'problem99']
pub fn problem99(input &i64, length usize) i64 {
	if length < 1 { return -1 }
	pair_count_value := unsafe { input[0] }
	if pair_count_value < 0 || pair_count_value > max_pair_count { return -1 }
	pair_count := int(pair_count_value)
	if length != usize(1 + 2 * pair_count) { return -1 }

	mut largest := f64(0.0)
	mut result_line := i64(0)
	for index in 0 .. pair_count {
		base := unsafe { input[1 + 2 * index] }
		exponent := unsafe { input[2 + 2 * index] }
		if base < 1 || base > max_base || exponent < 0 || exponent > max_exponent { return -1 }
		value := f64(exponent) * math.log10(f64(base))
		if value > largest {
			largest = value
			result_line = i64(index + 1)
		}
	}
	return result_line
}
