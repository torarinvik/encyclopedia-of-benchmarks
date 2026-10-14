package perfect_square

// Exact perfect-square check using integer binary search and division.
@(export)
perfect_square :: proc "c" (input: i64) -> i64 {
	if input < 0 do return 0
	if input < 2 do return 1
	number := u64(input)
	low := u64(1)
	high := number / 2
	for low <= high {
		middle := low + (high - low) / 2
		quotient := number / middle
		if quotient == middle {
			if number % middle == 0 do return 1
			low = middle + 1
		} else if quotient < middle {
			high = middle - 1
		} else {
			low = middle + 1
		}
	}
	return 0
}
