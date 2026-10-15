module kolakoski_sequence

@[export: 'kolakoski_sequence']
pub fn kolakoski_sequence(index i64) i64 {
	if index < 0 || index > 63 { return -1 }
	if index == 0 { return 1 }
	if index <= 2 { return 2 }

	mut encoded := u64(6)
	mut read_bit := u64(4)
	mut write_bit := u64(8)
	target := u64(index)
	mut current_index := u64(3)
	mut next_element := i64(1)

	for current_index <= target {
		run_length := u64(1) + (encoded / read_bit) % u64(2)
		mut emitted := u64(0)
		for emitted < run_length {
			if next_element == 2 { encoded += write_bit }
			if current_index == target { return next_element }
			current_index++
			write_bit *= 2
			emitted++
		}
		read_bit *= 2
		next_element = 3 - next_element
	}
	return -1
}
