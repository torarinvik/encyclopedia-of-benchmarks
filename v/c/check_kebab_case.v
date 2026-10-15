module check_kebab_case

const max_length = 4096

fn is_ascii_word(value i64) bool {
	return (value >= 97 && value <= 122) || (value >= 65 && value <= 90) ||
		(value >= 48 && value <= 57)
}

@[export: 'check_kebab_case']
pub fn check_kebab_case(values &i64, length usize) i64 {
	if length > max_length { return -2 }
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 32 || value > 126 { return -2 }
	}
	for index in 0 .. int(length) {
		if unsafe { values[index] } == 95 { return 0 }
	}
	if length < 3 { return 0 }
	for index in 1 .. int(length) - 1 {
		if unsafe { values[index] } == 45 && is_ascii_word(unsafe { values[index - 1] }) &&
			is_ascii_word(unsafe { values[index + 1] }) { return 1 }
	}
	return 0
}
