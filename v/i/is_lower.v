module is_lower

const max_length = 4096

@[export: 'is_lower']
pub fn is_lower(values &i64, length usize) i64 {
	if length > max_length { return -1 }
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 32 || value > 126 { return -1 }
		if value >= 65 && value <= 90 { return 0 }
	}
	return 1
}
