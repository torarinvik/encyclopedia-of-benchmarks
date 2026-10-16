module problem104

const max_fibonacci_index = 1000002
const max_limbs = 24000
const limb_base = u64(1000000000)

fn is_pandigital_1_to_9(value_value u32) bool {
	mut value := value_value
	mut mask := u16(0)
	for _ in 0 .. 9 {
		digit := value % 10
		bit := u16(1) << digit
		if digit == 0 || (mask & bit) != 0 { return false }
		mask |= bit
		value /= 10
	}
	return value == 0 && mask == 0x3fe
}
fn power_of_ten(exponent u32) u32 {
	mut value := u32(1)
	for _ in 0 .. int(exponent) { value *= 10 }
	return value
}
fn leading_nine_digits(limbs &u32, length int) u32 {
	top := unsafe { limbs[length - 1] }
	mut width := u32(0)
	mut value := top
	for value > 0 { width++; value /= 10 }
	if width >= 9 || length == 1 { return top }
	fill := 9 - width
	next_prefix := unsafe { limbs[length - 2] } / power_of_ten(width)
	return top * power_of_ten(fill) + next_prefix
}

@[export: 'problem104']
pub fn problem104(placeholder i64) i64 {
	if placeholder != 0 { return -1 }
	mut first_buffer := []u32{len: max_limbs}
	mut second_buffer := []u32{len: max_limbs}
	first_buffer[0] = 1
	second_buffer[0] = 1
	mut previous := unsafe { &first_buffer[0] }
	mut current := unsafe { &second_buffer[0] }
	mut previous_length := 1
	mut current_length := 1
	for index in 3 .. max_fibonacci_index + 1 {
		sum_length := if previous_length > current_length { previous_length } else { current_length }
		mut carry := u64(0)
		unsafe {
			for limb in 0 .. sum_length {
				left := if limb < previous_length { u64(previous[limb]) } else { u64(0) }
				right := if limb < current_length { u64(current[limb]) } else { u64(0) }
				sum := left + right + carry
				previous[limb] = u32(sum % limb_base)
				carry = sum / limb_base
			}
		}
		next_length := sum_length
		if carry != 0 {
			if next_length == max_limbs { return -1 }
			unsafe { previous[next_length] = u32(carry) }
			next_length++
		}
		temporary := previous
		previous = current
		current = temporary
		previous_length = current_length
		current_length = next_length
		if is_pandigital_1_to_9(unsafe { current[0] })
			&& is_pandigital_1_to_9(leading_nine_digits(current, current_length)) { return i64(index) }
	}
	return -1
}
