module check_flat_case

const max_length = 4096

// Check whether the bounded ASCII input is entirely lowercase letters.
@[export: 'check_flat_case']
pub fn check_flat_case(values &i64, length usize) i64 {
	if length > max_length { return -2 }
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 32 || value > 126 { return -2 }
	}
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 97 || value > 122 { return 0 }
	}
	return 1
}
