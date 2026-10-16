package problem104

MAX_FIBONACCI_INDEX :: 1_000_002
MAX_LIMBS :: 24_000
LIMB_BASE :: u64(1_000_000_000)

is_pandigital_1_to_9 :: proc(value_value: u32) -> bool {
	value := value_value
	mask: u16 = 0
	for index := 0; index < 9; index += 1 {
		digit := value % 10
		bit := u16(1) << digit
		if digit == 0 || (mask & bit) != 0 do return false
		mask |= bit
		value /= 10
	}
	return value == 0 && mask == 0x3fe
}
power_of_ten :: proc(exponent: u32) -> u32 {
	value: u32 = 1
	for index := u32(0); index < exponent; index += 1 do value *= 10
	return value
}
leading_nine_digits :: proc(limbs: [^]u32, length: int) -> u32 {
	top := limbs[length - 1]
	width: u32 = 0
	value := top
	for value > 0 { width += 1; value /= 10 }
	if width >= 9 || length == 1 do return top
	fill := 9 - width
	next_prefix := limbs[length - 2] / power_of_ten(width)
	return top * power_of_ten(fill) + next_prefix
}

@(export)
problem104 :: proc "c" (placeholder: i64) -> i64 {
	if placeholder != 0 do return -1
	first_buffer: [MAX_LIMBS]u32
	second_buffer: [MAX_LIMBS]u32
	first_buffer[0] = 1
	second_buffer[0] = 1
	previous := &first_buffer[0]
	current := &second_buffer[0]
	previous_length := 1
	current_length := 1
	for index := 3; index <= MAX_FIBONACCI_INDEX; index += 1 {
		sum_length := previous_length
		if current_length > sum_length do sum_length = current_length
		carry: u64 = 0
		for limb := 0; limb < sum_length; limb += 1 {
			left: u64 = 0
			right: u64 = 0
			if limb < previous_length do left = u64(previous[limb])
			if limb < current_length do right = u64(current[limb])
			sum := left + right + carry
			previous[limb] = u32(sum % LIMB_BASE)
			carry = sum / LIMB_BASE
		}
		next_length := sum_length
		if carry != 0 {
			if next_length == MAX_LIMBS do return -1
			previous[next_length] = u32(carry)
			next_length += 1
		}
		temporary := previous
		previous = current
		current = temporary
		previous_length = current_length
		current_length = next_length
		if is_pandigital_1_to_9(current[0]) && is_pandigital_1_to_9(leading_nine_digits(current, current_length)) do return i64(index)
	}
	return -1
}
