package problem73

Max_Denominator :: 12_000

gcd_i64 :: proc "contextless" (left_value, right_value: i64) -> i64 {
	left := left_value
	right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@(export)
problem73 :: proc "c" (max_denominator: i64) -> i64 {
	if max_denominator < 0 || max_denominator > Max_Denominator do return -1
	count := i64(0)
	for denominator := i64(0); denominator <= max_denominator; denominator += 1 {
		numerator_start := denominator / 3 + 1
		numerator_step := i64(1)
		if denominator % 2 == 0 {
			numerator_start += 1 - numerator_start % 2
			numerator_step = 2
		}
		numerator_end := (denominator + 1) / 2
		for numerator := numerator_start; numerator < numerator_end; numerator += numerator_step {
			if gcd_i64(numerator, denominator) == 1 do count += 1
		}
	}
	return count
}
