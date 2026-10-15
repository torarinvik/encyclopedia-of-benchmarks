package friendly_numbers

// Preserve the pinned JavaScript FriendlyNumbers divisor-loop behavior.
abundancy_index :: proc(number: u64) -> f64 {
	sum := number
	for divisor := u64(1); divisor * 2 < number; divisor += 1 {
		if number % divisor == 0 do sum += divisor
	}
	return f64(sum) / f64(number)
}

@(export)
friendly_numbers :: proc "c" (first, second: u64) -> i64 {
	if first == 0 || second == 0 || first == second || first > 1000 || second > 1000 do return -1
	if abundancy_index(first) == abundancy_index(second) do return 1
	return 0
}
