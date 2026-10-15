package keith_number_checker

// Preserve the digit-window recurrence used by the pinned C# checker.
@(export)
keith_number_checker :: proc "c" (number: i64) -> i64 {
	if number < 2 || number > 1000 do return -1
	original := number
	temp := number
	digits := i64(0)
	for temp != 0 {
		digits += 1
		temp /= 10
	}

	terms := make([]i64, int(number))
	temp = number
	for i := digits - 1; i >= 0; i -= 1 {
		terms[i] = temp % 10
		temp /= 10
	}
	sum := i64(0)
	k := digits
	for sum < original {
		sum = 0
		for j := i64(1); j <= digits; j += 1 { sum += terms[k - j] }
		terms[k] = sum
		k += 1
	}
	return if sum == original { i64(1) } else { i64(0) }
}
