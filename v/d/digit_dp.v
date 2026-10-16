module digit_dp

const max_digits = 19
const max_digit_sum = 171
const max_input_length = 4
const min_bound = i64(-1)
const max_bound = i64(1_000_000_000_000_000_000)

fn count_up_to(bound_value i64, target int) i64 {
	if bound_value < 0 { return 0 }
	mut bound := bound_value
	mut digits := [max_digits]usize{}
	mut digit_count := 0
	for {
		digits[digit_count] = usize(bound % 10)
		digit_count++
		bound /= 10
		if bound == 0 { break }
	}

	mut loose := [max_digit_sum + 1]i64{}
	mut tight := [max_digit_sum + 1]i64{}
	tight[0] = 1
	for digit_count > 0 {
		digit_count--
		limit := int(digits[digit_count])
		mut next_loose := [max_digit_sum + 1]i64{}
		mut next_tight := [max_digit_sum + 1]i64{}
		for sum in 0 .. target + 1 {
			for digit in 0 .. 10 {
				if sum + digit > target { break }
				next_loose[sum + digit] += loose[sum]
			}
			for digit in 0 .. limit + 1 {
				if sum + digit > target { break }
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

@[export: 'digit_dp']
pub fn digit_dp(input &i64, length usize) i64 {
	if unsafe { input == nil } || length > max_input_length || length != 3 { return -1 }
	lower := unsafe { input[0] }
	upper := unsafe { input[1] }
	target_value := unsafe { input[2] }
	if lower < min_bound || lower > max_bound || upper < min_bound || upper > max_bound { return -1 }
	if target_value < -2147483648 || target_value > 2147483647 { return -1 }
	if lower > upper || target_value < 0 || target_value > max_digit_sum { return 0 }
	count_up_to(upper, int(target_value)) - count_up_to(lower - 1, int(target_value))
}
