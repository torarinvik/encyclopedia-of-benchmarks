module problem71

const max_denominator = i64(1_000_000)

fn gcd_positive(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@[export: 'problem71']
pub fn problem71(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 3 {
		return -1
	}
	target_numerator := unsafe { input[0] }
	target_denominator := unsafe { input[1] }
	limit := unsafe { input[2] }
	if target_numerator < 1 || target_denominator <= target_numerator ||
		target_denominator > max_denominator || limit < 1 || limit > max_denominator ||
		gcd_positive(target_numerator, target_denominator) != 1 {
		return -1
	}

	mut best_numerator := i64(0)
	mut best_denominator := i64(1)
	mut current_denominator := i64(1)
	for current_denominator <= limit {
		mut current_numerator := current_denominator * target_numerator / target_denominator
		if current_denominator % target_denominator == 0 {
			current_numerator--
		}
		if current_numerator * best_denominator > current_denominator * best_numerator {
			best_numerator = current_numerator
			best_denominator = current_denominator
		}
		current_denominator++
	}
	return best_numerator
}
