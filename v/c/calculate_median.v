const max_length = 1024

@[export: 'calculate_median']
pub fn calculate_median(values &i64, length usize) i64 {
	if length < 1 || length > max_length { return i64(-9223372036854775808) }
	middle := int(length) / 2
	if length % 2 != 0 { return unsafe { values[middle] * 2 } }
	return unsafe { values[middle - 1] + values[middle] }
}
