package pell_number

@(export)
pell_number :: proc "c" (index: i64) -> i64 {
	if index < 0 || index > 50 do return -1
	if index == 0 do return 0
	previous := i64(0)
	current := i64(1)
	for i := i64(2); i <= index; i += 1 {
		next := 2 * current + previous
		previous = current
		current = next
	}
	return current
}
