package problem71

import "core:c"

MAX_DENOMINATOR :: i64(1_000_000)

gcd_positive :: proc(left_value, right_value: i64) -> i64 {
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
problem71 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	target_numerator := input[0]
	target_denominator := input[1]
	limit := input[2]
	if target_numerator < 1 || target_denominator <= target_numerator ||
	   target_denominator > MAX_DENOMINATOR || limit < 1 || limit > MAX_DENOMINATOR ||
	   gcd_positive(target_numerator, target_denominator) != 1 do return -1

	best_numerator: i64 = 0
	best_denominator: i64 = 1
	for current_denominator: i64 = 1; current_denominator <= limit; current_denominator += 1 {
		current_numerator := current_denominator * target_numerator / target_denominator
		if current_denominator % target_denominator == 0 do current_numerator -= 1
		if current_numerator * best_denominator > current_denominator * best_numerator {
			best_numerator = current_numerator
			best_denominator = current_denominator
		}
	}
	return best_numerator
}
