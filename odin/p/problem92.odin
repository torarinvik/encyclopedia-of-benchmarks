package problem92

const MAX_LIMIT: i64 = 10_000_000
const MAX_DIGITS = 7
const MAX_SUM = MAX_DIGITS * 81 + 1

digit_square_sum :: proc(value: u32) -> u32 {
	total := u32(0)
	number := value
	for number != 0 {
		digit := number % 10
		total += digit * digit
		number /= 10
	}
	return total
}

reaches_89 :: proc(value: u32) -> bool {
	number := value
	for number != 1 && number != 89 { number = digit_square_sum(number) }
	return number == 89
}

@(export)
problem92 :: proc "c" (number: i64) -> i64 {
	if number < 0 || number > MAX_LIMIT do return -1
	digits: [MAX_DIGITS]u32
	reversed: [MAX_DIGITS]u32
	digit_count := 0
	if number > 1 {
		remaining := u32(number - 1)
		for remaining != 0 {
			reversed[digit_count] = remaining % 10
			digit_count += 1
			remaining /= 10
		}
		for index := 0; index < digit_count; index += 1 {
			digits[index] = reversed[digit_count - index - 1]
		}
	} else {
		digits[0] = 0
		digit_count = 1
	}
	sum_limit := digit_count * 81 + 1
	tight, free_counts, next_tight, next_free: [MAX_SUM]i64
	for sum := 0; sum < MAX_SUM; sum += 1 { tight[sum] = 0; free_counts[sum] = 0 }
	tight[0] = 1
	for position := 0; position < digit_count; position += 1 {
		for sum := 0; sum < MAX_SUM; sum += 1 { next_tight[sum] = 0; next_free[sum] = 0 }
		bound_digit := digits[position]
		for sum := 0; sum < sum_limit; sum += 1 {
			if tight[sum] != 0 {
				for digit := u32(0); digit <= bound_digit; digit += 1 {
					next_sum := sum + int(digit*digit)
					if next_sum >= sum_limit do continue
					if digit == bound_digit { next_tight[next_sum] += tight[sum] }
					else { next_free[next_sum] += tight[sum] }
				}
			}
			if free_counts[sum] != 0 {
				for digit := 0; digit <= 9; digit += 1 {
					next_sum := sum + digit*digit
					if next_sum < sum_limit { next_free[next_sum] += free_counts[sum] }
				}
			}
		}
		for sum := 0; sum < MAX_SUM; sum += 1 { tight[sum] = next_tight[sum]; free_counts[sum] = next_free[sum] }
	}
	result := i64(0)
	for sum := 1; sum < sum_limit; sum += 1 {
		if reaches_89(u32(sum)) { result += tight[sum] + free_counts[sum] }
	}
	return result
}
