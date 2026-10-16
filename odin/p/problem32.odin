package problem32

next_permutation :: proc(digits: ^[9]i64) -> bool {
	pivot := 7
	for pivot >= 0 && digits[pivot] >= digits[pivot + 1] do pivot -= 1
	if pivot < 0 do return false
	successor := 8
	for digits[successor] <= digits[pivot] do successor -= 1
	digits[pivot], digits[successor] = digits[successor], digits[pivot]
	left := pivot + 1
	right := 8
	for left < right {
		digits[left], digits[right] = digits[right], digits[left]
		left += 1
		right -= 1
	}
	return true
}

@(export)
problem32 :: proc "c" (ignored: i64) -> i64 {
	if ignored != 0 do return -1
	digits: [9]i64 = {1, 2, 3, 4, 5, 6, 7, 8, 9}
	seen: [10000]bool
	for value := 0; value < 10000; value += 1 { seen[value] = false }
	more := true
	sum := i64(0)
	for more {
		product := digits[5] * 1000 + digits[6] * 100 + digits[7] * 10 + digits[8]
		two_digit := digits[0] * 10 + digits[1]
		three_digit := digits[2] * 100 + digits[3] * 10 + digits[4]
		four_digit := digits[1] * 1000 + digits[2] * 100 + digits[3] * 10 + digits[4]
		if two_digit * three_digit == product || digits[0] * four_digit == product {
			if !seen[product] {
				seen[product] = true
				sum += product
			}
		}
		more = next_permutation(&digits)
	}
	return sum
}
