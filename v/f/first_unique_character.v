module first_unique_character

const max_length = 1024

// Return the first lowercase ASCII letter whose frequency is one.
@[export: 'first_unique_character']
pub fn first_unique_character(values &i64, length usize) i64 {
	if length > max_length { return -2 }
	mut counts := [26]int{}
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 97 || value > 122 { return -2 }
		counts[int(value - 97)]++
	}
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if counts[int(value - 97)] == 1 { return i64(index) }
	}
	return -1
}
