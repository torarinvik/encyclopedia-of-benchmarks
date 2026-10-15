module is_sorted_array

const max_length = 100000
const max_safe_integer = i64(9007199254740991)

@[export: 'is_sorted_array']
pub fn is_sorted_array(values &i64, length usize) i64 {
	if length > max_length { return -1 }
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < -max_safe_integer || value > max_safe_integer { return -1 }
	}
	if length < 2 { return 1 }
	for index in 0 .. int(length) - 1 {
		left := unsafe { values[index] }
		right := unsafe { values[index + 1] }
		if left >= right { return 0 }
	}
	return 1
}
