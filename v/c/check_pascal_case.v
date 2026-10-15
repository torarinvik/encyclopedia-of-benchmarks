module check_pascal_case

const max_length = 4096

// Check the bounded ASCII Pascal-case predicate.
@[export: 'check_pascal_case']
pub fn check_pascal_case(values &i64, length usize) i64 {
	if length > max_length { return -2 }
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 32 || value > 126 { return -2 }
	}
	if length == 0 { return 0 }
	first := unsafe { values[0] }
	if first < 65 || first > 90 { return 0 }
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if !((value >= 97 && value <= 122) || (value >= 65 && value <= 90)) { return 0 }
	}
	return 1
}
