package problem3

@(export)
problem3 :: proc "c" (number: i64) -> i64 {
	if number < 2 || number > 600_851_475_143 do return -1
	remaining := number
	largest := i64(1)
	for factor := i64(2); factor <= remaining / factor; {
		if remaining % factor == 0 {
			largest = factor
			remaining /= factor
		} else {
			factor += 1
		}
	}
	if remaining > 1 do return remaining
	return largest
}
