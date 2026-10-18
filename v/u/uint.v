module uint_base_conversion

const max_digits = 64
const max_output_digits = 1664

fn trim(mut value []u32) []u32 {
	mut end := value.len
	for end > 0 && value[end - 1] == 0 { end-- }
	return value[..end]
}


fn from_small(value_input u32, base u32) []u32 {
	mut value := value_input
	mut result := []u32{}
	for value > 0 { result << value % base; value /= base }
	return result
}

fn add(mut left []u32, right []u32, base u32) {
	mut index := 0
	mut carry := u64(0)
	for index < right.len || carry != 0 {
		a := if index < left.len { u64(left[index]) } else { u64(0) }
		b := if index < right.len { u64(right[index]) } else { u64(0) }
		sum := carry + a + b
		if index == left.len { left << u32(0) }
		left[index] = u32(sum % u64(base))
		carry = sum / u64(base)
		index++
	}
	for left.len < right.len { left << right[left.len] }
}

fn multiply(left []u32, right []u32, base u32) []u32 {
	if left.len == 0 || right.len == 0 { return []u32{} }
	mut result := []u32{len: left.len + right.len, init: u32(0)}
	for i in 0 .. left.len {
		mut carry := u64(0)
		for j in 0 .. right.len {
			at := i + j
			product := u64(left[i]) * u64(right[j]) + u64(result[at]) + carry
			result[at] = u32(product % u64(base))
			carry = product / u64(base)
		}
		mut at := i + right.len
		for carry != 0 {
			sum := u64(result[at]) + carry
			result[at] = u32(sum % u64(base))
			carry = sum / u64(base)
			at++
			if at > result.len { result << u32(0) }
		}
	}
	return trim(mut result)
}

fn power(factor_input []u32, exponent_input int, base u32) []u32 {
	mut factor := factor_input.clone()
	mut exponent := exponent_input
	mut result := from_small(1, base)
	for exponent > 0 {
		if (exponent & 1) == 1 { result = multiply(result, factor, base) }
		exponent >>= 1
		if exponent > 0 { factor = multiply(factor, factor, base) }
	}
	return result
}

fn convert_base(digits []u32, source_base u32, target_base u32) []u32 {
	if digits.len == 0 { return []u32{} }
	if source_base == target_base { return digits.clone() }
	if digits.len == 1 { return from_small(digits[0], target_base) }
	middle := digits.len / 2
	mut low := convert_base(digits[..middle], source_base, target_base)
	high := convert_base(digits[middle..], source_base, target_base)
	scale := power(from_small(source_base, target_base), middle, target_base)
	shifted := multiply(high, scale, target_base)
	add(mut low, shifted, target_base)
	return low
}

@[export: 'uint_convert_base']
pub fn uint_convert_base(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_digits + 4 { return -1 }
	unsafe {
		source_value := input[0]
		target_value := input[1]
		count_value := input[2]
		if source_value < 2 || source_value > (i64(1) << 26) || target_value < 2 || target_value > (i64(1) << 26) ||
			count_value < 0 || count_value > max_digits || length != usize(count_value + 3) { return -1 }
		source_base := u32(source_value)
		target_base := u32(target_value)
		count := int(count_value)
		mut digits := []u32{len: count, init: u32(0)}
		for i in 0 .. count {
			if input[i + 3] < 0 || input[i + 3] >= source_value { return -1 }
			digits[i] = u32(input[i + 3])
		}
		if count > 0 && digits[count - 1] == 0 { return -1 }
		converted := convert_base(digits, source_base, target_base)
		if converted.len > max_output_digits { return -1 }
		bytes := converted.len * 4
		if output == nil || capacity < usize(bytes) { return -2 }
		for i in 0 .. converted.len {
			for byte in 0 .. 4 { output[i * 4 + byte] = u8(converted[i] >> u32(byte * 8)) }
		}
		return i64(bytes)
	}
}
