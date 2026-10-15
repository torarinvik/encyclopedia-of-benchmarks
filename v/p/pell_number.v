module pell_number

@[export: 'pell_number']
pub fn pell_number(index i64) i64 {
	if index < 0 || index > 50 { return -1 }
	if index == 0 { return 0 }
	mut previous := i64(0)
	mut current := i64(1)
	for i := i64(2); i <= index; i++ {
		next := 2 * current + previous
		previous = current
		current = next
	}
	return current
}
