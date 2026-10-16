module problem92

const max_limit = i64(10_000_000)
const max_digits = 7
const max_sum = max_digits * 81 + 1

fn digit_square_sum(value u32) u32 {
	mut number := value
	mut total := u32(0)
	for number != 0 {
		digit := number % 10
		total += digit * digit
		number /= 10
	}
	return total
}

fn reaches_89(value u32) bool {
	mut number := value
	for number != 1 && number != 89 { number = digit_square_sum(number) }
	return number == 89
}

@[export: 'problem92']
pub fn problem92(number i64) i64 {
	if number < 0 || number > max_limit { return -1 }
	mut digits := [max_digits]u32{}
	mut reversed := [max_digits]u32{}
	mut digit_count := 0
	if number > 1 {
		mut remaining := u32(number - 1)
		for remaining != 0 {
			reversed[digit_count] = remaining % 10
			digit_count++
			remaining /= 10
		}
		for index in 0 .. digit_count { digits[index] = reversed[digit_count - index - 1] }
	} else {
		digits[0] = 0
		digit_count = 1
	}
	sum_limit := digit_count * 81 + 1
	mut tight := []i64{len: max_sum}
	mut free_counts := []i64{len: max_sum}
	mut next_tight := []i64{len: max_sum}
	mut next_free := []i64{len: max_sum}
	tight[0] = 1
	for position in 0 .. digit_count {
		for sum in 0 .. max_sum { next_tight[sum] = 0; next_free[sum] = 0 }
		bound_digit := digits[position]
		for sum in 0 .. sum_limit {
			if tight[sum] != 0 {
				for digit in u32(0) .. bound_digit + 1 {
					next_sum := sum + int(digit * digit)
					if next_sum >= sum_limit { continue }
					if digit == bound_digit { next_tight[next_sum] += tight[sum] }
					else { next_free[next_sum] += tight[sum] }
				}
			}
			if free_counts[sum] != 0 {
				for digit in 0 .. 10 {
					next_sum := sum + digit * digit
					if next_sum < sum_limit { next_free[next_sum] += free_counts[sum] }
				}
			}
		}
		for sum in 0 .. max_sum { tight[sum] = next_tight[sum]; free_counts[sum] = next_free[sum] }
	}
	mut result := i64(0)
	for sum in 1 .. sum_limit {
		if reaches_89(u32(sum)) { result += tight[sum] + free_counts[sum] }
	}
	return result
}
