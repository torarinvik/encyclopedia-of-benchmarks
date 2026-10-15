module harmonic_mean

const max_length = 64
const invalid_result = -1.0e300

@[export: 'harmonic_mean']
pub fn harmonic_mean(values &i64, length usize) f64 {
	if unsafe { values == nil } || length == 0 || length > max_length { return invalid_result }
	unsafe {
		mut reciprocal_sum := 0.0
		for index in 0 .. int(length) {
			value := values[index]
			if value < 1 || value > 1000 { return invalid_result }
			reciprocal_sum += 1.0 / f64(value)
		}
		return f64(length) / reciprocal_sum
	}
}
