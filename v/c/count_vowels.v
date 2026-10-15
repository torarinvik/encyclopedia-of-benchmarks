module count_vowels

const max_length = 4096

// Count ASCII vowels in a bounded string represented by byte values.
@[export: 'count_vowels']
pub fn count_vowels(values &i64, length usize) i64 {
	if length == 0 || length > max_length { return -2 }
	if length == 1 && unsafe { values[0] } == 48 { return -2 }
	mut count := i64(0)
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 0 || value > 127 || value == 44 { return -2 }
		if value == 97 || value == 101 || value == 105 || value == 111 || value == 117 || value == 65 || value == 69 || value == 73 || value == 79 || value == 85 {
			count++
		}
	}
	return count
}
