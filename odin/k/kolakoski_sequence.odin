package kolakoski_sequence

@(export)
kolakoski_sequence :: proc "c" (index: i64) -> i64 {
	if index < 0 || index > 63 do return -1
	if index == 0 do return 1
	if index <= 2 do return 2

	encoded := u64(6)
	read_bit := u64(4)
	write_bit := u64(8)
	target := u64(index)
	current_index := u64(3)
	next_element := i64(1)

	for current_index <= target {
		run_length := u64(1) + (encoded / read_bit) % u64(2)
		for emitted := u64(0); emitted < run_length; emitted += 1 {
			if next_element == 2 do encoded += write_bit
			if current_index == target do return next_element
			current_index += 1
			write_bit *= 2
		}
		read_bit *= 2
		next_element = 3 - next_element
	}
	return -1
}

main :: proc() {}
