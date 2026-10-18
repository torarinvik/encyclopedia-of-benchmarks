package uint

import "core:c"

MAX_DIGITS :: 64
MAX_OUTPUT_DIGITS :: 1665

Big :: struct { digits: [MAX_OUTPUT_DIGITS]u32, len: int }

trim :: proc "contextless" (value: ^Big) {
	for value.len > 0 && value.digits[value.len - 1] == 0 do value.len -= 1
}

from_small :: proc "contextless" (value_input, base: u32) -> Big {
	value := value_input
	result := Big{}
	for value > 0 {
		result.digits[result.len] = value % base
		result.len += 1
		value /= base
	}
	return result
}

add :: proc "contextless" (left, right: ^Big, base: u32) {
	index := 0
	carry: u64 = 0
	for index < right.len || carry != 0 {
		a: u64 = 0
		b: u64 = 0
		if index < left.len do a = u64(left.digits[index])
		if index < right.len do b = u64(right.digits[index])
		sum := carry + a + b
		if index == left.len do left.len += 1
		left.digits[index] = u32(sum % u64(base))
		carry = sum / u64(base)
		index += 1
	}
	if left.len < right.len {
		for left.len < right.len {
			left.digits[left.len] = right.digits[left.len]
			left.len += 1
		}
	}
}

multiply :: proc "contextless" (left, right: ^Big, base: u32) -> Big {
	result := Big{}
	if left.len == 0 || right.len == 0 do return result
	result.len = left.len + right.len
	for i := 0; i < left.len; i += 1 {
		carry: u64 = 0
		for j := 0; j < right.len; j += 1 {
			at := i + j
			product := u64(left.digits[i]) * u64(right.digits[j]) + u64(result.digits[at]) + carry
			result.digits[at] = u32(product % u64(base))
			carry = product / u64(base)
		}
		at := i + right.len
		for carry != 0 {
			sum := u64(result.digits[at]) + carry
			result.digits[at] = u32(sum % u64(base))
			carry = sum / u64(base)
			at += 1
			if at > result.len do result.len = at
		}
	}
	trim(&result)
	return result
}

power :: proc "contextless" (factor_input: Big, exponent_input: int, base: u32) -> Big {
	factor := factor_input
	exponent := exponent_input
	result := from_small(1, base)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = multiply(&result, &factor, base)
		exponent >>= 1
		if exponent > 0 do factor = multiply(&factor, &factor, base)
	}
	return result
}

convert_base :: proc "contextless" (digits: [^]u32, length: int, source_base, target_base: u32) -> Big {
	if length == 0 do return Big{}
	if source_base == target_base {
		result := Big{}
		result.len = length
		for i := 0; i < length; i += 1 do result.digits[i] = digits[i]
		return result
	}
	if length == 1 do return from_small(digits[0], target_base)
	middle := length / 2
	low := convert_base(digits, middle, source_base, target_base)
	high := convert_base(&digits[middle], length - middle, source_base, target_base)
	scale := power(from_small(source_base, target_base), middle, target_base)
	shifted := multiply(&high, &scale, target_base)
	add(&low, &shifted, target_base)
	return low
}

@(export)
uint_convert_base :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_DIGITS + 4 do return -1
	source_value, target_value, count_value := input[0], input[1], input[2]
	if source_value < 2 || source_value > (i64(1) << 26) || target_value < 2 || target_value > (i64(1) << 26) ||
		count_value < 0 || count_value > MAX_DIGITS || length != c.size_t(count_value + 3) do return -1
	source_base, target_base, count := u32(source_value), u32(target_value), int(count_value)
	var source_digits: [MAX_DIGITS]u32
	for i := 0; i < count; i += 1 {
		if input[i + 3] < 0 || input[i + 3] >= source_value do return -1
		source_digits[i] = u32(input[i + 3])
	}
	if count > 0 && source_digits[count - 1] == 0 do return -1
	result := convert_base(&source_digits[0], count, source_base, target_base)
	if result.len > MAX_OUTPUT_DIGITS do return -1
	bytes := result.len * 4
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i := 0; i < result.len; i += 1 {
		for byte := 0; byte < 4; byte += 1 do output[i * 4 + byte] = u8(result.digits[i] >> (byte * 8))
	}
	return i64(bytes)
}
