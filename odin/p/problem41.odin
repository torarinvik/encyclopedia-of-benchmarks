package problem41

const MAX_DIGITS :: 9

is_prime :: proc "contextless" (number: i64) -> bool {
	if number < 2 do return false
	if number < 4 do return true
	if number % 2 == 0 || number % 3 == 0 do return false
	for divisor := i64(5); divisor <= number / divisor; divisor += 6 {
		if number % divisor == 0 || number % (divisor + 2) == 0 do return false
	}
	return true
}

search :: proc "contextless" (digits, depth: int, used: u16, value: i64) -> i64 {
	if depth == digits do return if is_prime(value) then value else 0
	best := i64(0)
	for digit := 1; digit <= digits; digit += 1 {
		bit := u16(1) << digit
		if (used & bit) != 0 do continue
		candidate := search(digits, depth + 1, used | bit, value * 10 + i64(digit))
		if candidate > best do best = candidate
	}
	return best
}

@(export)
problem41 :: proc "c" (digits: i64) -> i64 {
	if digits < 1 || digits > MAX_DIGITS do return -1
	return search(int(digits), 0, 0, 0)
}
