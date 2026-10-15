module count_consonants

const max_length = 4096

@[export: 'count_consonants']
pub fn count_consonants(values &i64, length usize) i64 {
	if length == 0 || length > max_length { return -1 }
	if length == 1 && unsafe { values[0] } == 48 { return -1 }
	mut count := i64(0)
	for index in 0 .. int(length) {
		mut value := unsafe { values[index] }
		if value < 32 || value > 126 { return -1 }
		if value >= 65 && value <= 90 { value += 32 }
		if value >= 97 && value <= 122 && value != 97 && value != 101 && value != 105 && value != 111 && value != 117 {
			count++
		}
	}
	return count
}
