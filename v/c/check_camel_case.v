module check_camel_case

const max_length = 4096

// Check the bounded ASCII camel-case predicate.
@[export: 'check_camel_case']
pub fn check_camel_case(values &i64, length usize) i64 {
	if length > max_length { return -2 }
	if length == 0 { return 0 }
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 32 || value > 126 { return -2 }
	}
	first := unsafe { values[0] }
	if first < 97 || first > 122 { return 0 }
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if !((value >= 97 && value <= 122) || (value >= 65 && value <= 90)) { return 0 }
	}
	return 1
}
