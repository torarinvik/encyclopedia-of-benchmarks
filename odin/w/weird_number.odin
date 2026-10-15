package weird_number

@(export)
weird_number :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > 512 do return -1
	if value == 0 do return 0
	reachable: [513]bool
	reachable[0] = true
	divisor_sum: i64 = 0
	for divisor := i64(1); divisor <= value / 2; divisor += 1 {
		if value % divisor != 0 do continue
		divisor_sum += divisor
		for total := value; total >= divisor; total -= 1 {
			if reachable[int(total-divisor)] do reachable[int(total)] = true
		}
	}
	return i64(divisor_sum > value && !reachable[int(value)])
}
