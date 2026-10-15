package smith_number

is_prime :: proc(value: i64) -> bool {
	if value == 2 do return true
	if value < 2 || value % 2 == 0 do return false
	for divisor := i64(3); divisor <= value / divisor; divisor += 2 {
		if value % divisor == 0 do return false
	}
	return true
}

digit_sum :: proc(value_arg: i64) -> i64 {
	value := value_arg
	sum: i64 = 0
	for value != 0 {
		sum += value % 10
		value /= 10
	}
	return sum
}

prime_factor_digit_sum :: proc(value: i64) -> i64 {
	sum: i64 = 0
	remainder := value
	for factor := i64(2); factor <= value / factor; factor += 1 {
		for remainder % factor == 0 {
			sum += digit_sum(factor)
			remainder /= factor
		}
	}
	if remainder > 1 do sum += digit_sum(remainder)
	return sum
}

@(export)
smith_number :: proc "c" (value: i64) -> i64 {
	if value < 1 || value > 2147483647 do return -1
	if is_prime(value) do return 0
	return i64(digit_sum(value) == prime_factor_digit_sum(value))
}
