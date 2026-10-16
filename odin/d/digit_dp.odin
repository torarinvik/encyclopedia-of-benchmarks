package digit_dp

import "core:c"

MAX_DIGITS :: 19
MAX_DIGIT_SUM :: 171
MAX_INPUT_LENGTH :: 4
MIN_BOUND :: i64(-1)
MAX_BOUND :: i64(1_000_000_000_000_000_000)

count_up_to :: proc(bound_value: i64, target: int) -> i64 {
	if bound_value < 0 do return 0
	bound := bound_value
	var digits: [MAX_DIGITS]int
	digit_count := 0
	for {
		digits[digit_count] = int(bound % 10)
		digit_count += 1
		bound /= 10
		if bound == 0 do break
	}

	var loose: [MAX_DIGIT_SUM + 1]i64
	var tight: [MAX_DIGIT_SUM + 1]i64
	tight[0] = 1
	for digit_count > 0 {
		digit_count -= 1
		limit := digits[digit_count]
		var next_loose: [MAX_DIGIT_SUM + 1]i64
		var next_tight: [MAX_DIGIT_SUM + 1]i64
		for sum := 0; sum <= target; sum += 1 {
			for digit := 0; digit <= 9 && sum + digit <= target; digit += 1 {
				next_loose[sum + digit] += loose[sum]
			}
			for digit := 0; digit <= limit && sum + digit <= target; digit += 1 {
				if digit == limit {
					next_tight[sum + digit] += tight[sum]
				} else {
					next_loose[sum + digit] += tight[sum]
				}
			}
		}
		loose = next_loose
		tight = next_tight
	}
	return loose[target] + tight[target]
}

@(export)
digit_dp :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length > MAX_INPUT_LENGTH || length != 3 do return -1
	lower, upper, target_value := input[0], input[1], input[2]
	if lower < MIN_BOUND || lower > MAX_BOUND || upper < MIN_BOUND || upper > MAX_BOUND do return -1
	if target_value < -2147483648 || target_value > 2147483647 do return -1
	if lower > upper || target_value < 0 || target_value > MAX_DIGIT_SUM do return 0
	target := int(target_value)
	return count_up_to(upper, target) - count_up_to(lower - 1, target)
}
