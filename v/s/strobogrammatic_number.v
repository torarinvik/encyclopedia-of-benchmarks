module strobogrammatic_number

const max_input_length = 64

fn rotated_digit(value i64) i64 {
	match value {
		48 { return 48 }
		49 { return 49 }
		54 { return 57 }
		56 { return 56 }
		57 { return 54 }
		else { return -1 }
	}
}

@[export: 'strobogrammatic_number']
pub fn strobogrammatic_number(bytes &i64, length usize) i64 {
	if length > max_input_length { return -1 }
	for index in 0 .. length {
		value := unsafe { bytes[index] }
		if value < 0 || value > 127 { return -1 }
	}
	mut left := usize(0)
	mut right := length
	for left < right {
		right--
		if rotated_digit(unsafe { bytes[left] }) != unsafe { bytes[right] } { return 0 }
		left++
	}
	return 1
}
