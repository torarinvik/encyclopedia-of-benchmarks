package parity

// Return the parity of the set-bit count using Kernighan's bit clearing.
@(export)
parity :: proc "c" (number: i64) -> i64 {
	if number < 0 do return -1
	current := number
	result := i64(0)
	for current != 0 {
		result = result ~ 1
		current = current & (current - 1)
	}
	return result
}
