package problem4

is_palindrome :: proc(value: i64) -> bool {
	remaining := value
	reversed := i64(0)
	for remaining > 0 {
		reversed = reversed * 10 + remaining % 10
		remaining /= 10
	}
	return reversed == value
}

@(export)
problem4 :: proc "c" (digits: i64) -> i64 {
	if digits < 1 || digits > 3 do return -1
	minimum := i64(100)
	maximum := i64(999)
	if digits == 1 {
		minimum = 1
		maximum = 9
	} else if digits == 2 {
		minimum = 10
		maximum = 99
	}
	largest := i64(0)
	for first := maximum; first >= minimum && first * maximum > largest; first -= 1 {
		for second := maximum; second >= first && first * second > largest; second -= 1 {
			product := first * second
			if is_palindrome(product) do largest = product
		}
	}
	return largest
}
