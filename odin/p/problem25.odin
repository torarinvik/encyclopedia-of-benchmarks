package problem25

@(export)
problem25 :: proc "c" (requested_digits: i64) -> i64 {
	if requested_digits < 2 || requested_digits > 1000 do return -1
	previous: [1000]i64
	current: [1000]i64
	next: [1000]i64
	previous[0] = 1
	current[0] = 1
	active_digits := i64(1)
	index := i64(2)
	for active_digits < requested_digits {
		carry := i64(0)
		for position := i64(0); position < active_digits; position += 1 {
			total := previous[position] + current[position] + carry
			next[position] = total % 10
			carry = total / 10
		}
		if carry != 0 {
			next[active_digits] = carry
			active_digits += 1
		}
		for position := i64(0); position < active_digits; position += 1 {
			previous[position] = current[position]
			current[position] = next[position]
		}
		index += 1
	}
	return index
}
