module array_sum

@[export: 'array_sum']
pub fn array_sum(values &i64, length usize) i64 {
	if length < 1 { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 0 || count_value > 1024 { return -1 }
	count := usize(count_value)
	if length != count + 1 { return -1 }
	mut sum := i64(0)
	for i in 0 .. count {
		value := unsafe { values[i + 1] }
		if value < 0 || value > 1000000000 { return -1 }
		sum += value
	}
	return sum
}
