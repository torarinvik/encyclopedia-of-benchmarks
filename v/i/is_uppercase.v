module is_uppercase

const max_length = 4096

@[export: 'is_uppercase']
pub fn is_uppercase(values &i64, length usize) i64 {
	if length > max_length { return -1 }
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 32 || value > 126 { return -1 }
		if value >= 97 && value <= 122 { return 0 }
	}
	return 1
}
