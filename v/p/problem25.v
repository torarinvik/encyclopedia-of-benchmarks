module problem25

@[export: 'problem25']
pub fn problem25(requested_digits i64) i64 {
	if requested_digits < 2 || requested_digits > 1000 { return -1 }
	mut previous := [1000]i64{}
	mut current := [1000]i64{}
	mut next := [1000]i64{}
	previous[0] = 1
	current[0] = 1
	mut active_digits := 1
	mut index := i64(2)
	for active_digits < int(requested_digits) {
		mut carry := i64(0)
		for position := 0; position < active_digits; position++ {
			total := previous[position] + current[position] + carry
			next[position] = total % 10
			carry = total / 10
		}
		if carry != 0 {
			next[active_digits] = carry
			active_digits++
		}
		for position := 0; position < active_digits; position++ {
			previous[position] = current[position]
			current[position] = next[position]
		}
		index++
	}
	return index
}
