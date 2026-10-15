module greatest_common_factor

const max_items = 256
const max_safe_integer = i64(9007199254740991)
const invalid_result = i64(-9223372036854775807 - 1)

fn gcd_nonnegative(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@[export: 'greatest_common_factor']
pub fn greatest_common_factor(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > max_items + 1 { return invalid_result }
	unsafe {
		count := values[0]
		if count < 1 || count > max_items || length != usize(count + 1) { return invalid_result }
		mut result := values[1]
		if result < 0 || result > max_safe_integer { return invalid_result }
		for index in 2 .. int(length) {
			value := values[index]
			if value < 0 || value > max_safe_integer { return invalid_result }
			result = gcd_nonnegative(result, value)
		}
		return result
	}
}
