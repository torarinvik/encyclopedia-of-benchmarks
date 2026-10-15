const max_values_limit = 256
const max_values_invalid = i64(-9223372036854775807) - 1

@[export: 'max_values']
pub fn max_values(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 1 || length > max_values_limit + 1 { return max_values_invalid }
	count := unsafe { values[0] }
	if count < 1 || count > max_values_limit || length != usize(count + 1) { return max_values_invalid }
	mut result := unsafe { values[1] }
	if result < -2147483648 || result > 2147483647 { return max_values_invalid }
	for index in 2 .. int(length) {
		value := unsafe { values[index] }
		if value < -2147483648 || value > 2147483647 { return max_values_invalid }
		if value > result { result = value }
	}
	return result
}
