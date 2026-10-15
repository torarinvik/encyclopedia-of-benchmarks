package amicable_number

proper_divisor_sum :: proc "contextless" (number: u64) -> u64 {
	if number <= 1 do return 0
	sum := u64(1)
	for divisor := u64(2); divisor <= number / divisor; divisor += 1 {
		if number % divisor == 0 {
			sum += divisor
			partner := number / divisor
			if partner != divisor do sum += partner
		}
	}
	return sum
}

@(export)
amicable_number :: proc "contextless" (left, right: u64) -> i64 {
	if left < 1 || left > 1_000_000_000 || right < 1 || right > 1_000_000_000 do return -1
	if left == right do return 0
	return i64(proper_divisor_sum(left) == right && proper_divisor_sum(right) == left)
}
