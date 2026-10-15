module check_snake_case

const max_length = 4096

@[export: 'check_snake_case']
pub fn check_snake_case(values &i64, length usize) i64 {
	if length > max_length { return -2 }
	mut found := i64(0)
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 32 || value > 126 { return -2 }
		if value == 95 { found = 1 }
	}
	return found
}
