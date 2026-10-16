module problem207

const invalid_result = -1.0e300
const min_proportion = 1.0e-5
const max_proportion = 1.0
const max_partitions = i64(5000000)

fn is_power_of_two(value i64) bool {
	return value > 0 && (value & (value - 1)) == 0
}

@[export: 'problem207']
pub fn problem207(max_proportion f64) f64 {
	if max_proportion != max_proportion || max_proportion < min_proportion || max_proportion > 1.0 {
		return invalid_result
	}
	mut partitions := i64(0)
	mut perfect_partitions := i64(0)
	for partitions < max_partitions {
		partitions++
		candidate := partitions * (partitions + 1)
		if is_power_of_two(partitions + 1) { perfect_partitions++ }
		if f64(perfect_partitions) / f64(partitions) < max_proportion {
			return f64(candidate)
		}
	}
	return invalid_result
}
