package binary_shifts

import "core:c"

unsigned_bits :: proc(value: u32, bits: [^]u8) -> c.size_t {
	remaining := value
	length := c.size_t(0)
	for {
		bits[length] = u8('0') + u8(remaining & 1)
		length += 1
		remaining >>= 1
		if remaining == 0 do break
	}
	for left := c.size_t(0); left < length / 2; left += 1 {
		right := length - left - 1
		temporary := bits[left]
		bits[left] = bits[right]
		bits[right] = temporary
	}
	return length
}

@(export)
binary_shifts :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 3 do return -1
	operation, number, shift := values[0], values[1], values[2]
	if operation < 0 || operation > 2 || number < -2_147_483_647 || number > 2_147_483_647 ||
		shift < 0 || shift > 31 || (operation < 2 && number < 0) do return -1

	bits: [80]u8
	result: [82]u8
	bits_length := c.size_t(0)
	result_length := c.size_t(0)
	if operation == 0 || operation == 1 {
		bits_length = unsigned_bits(u32(number), &bits[0])
		result[0] = u8('0'); result[1] = u8('b'); result_length = 2
		if operation == 0 {
			for i := c.size_t(0); i < bits_length; i += 1 { result[result_length] = bits[i]; result_length += 1 }
			for i := i64(0); i < shift; i += 1 { result[result_length] = u8('0'); result_length += 1 }
		} else if c.size_t(shift) >= bits_length {
			result[result_length] = u8('0'); result_length += 1
		} else {
			for i := c.size_t(0); i < bits_length - c.size_t(shift); i += 1 { result[result_length] = bits[i]; result_length += 1 }
		}
	} else {
		if number >= 0 {
			bits[0] = u8('0')
			bits_length = 1 + unsigned_bits(u32(number), &bits[1])
		} else {
			magnitude := u32(-number)
			magnitude_length := unsigned_bits(magnitude, &bits[0])
			complement := (u32(1) << magnitude_length) - magnitude
			complement_bits: [40]u8
			complement_length := unsigned_bits(complement, &complement_bits[0])
			bits[0] = u8('1')
			position := c.size_t(1)
			for i := complement_length; i < magnitude_length; i += 1 { bits[position] = u8('0'); position += 1 }
			for i := c.size_t(0); i < complement_length; i += 1 { bits[position] = complement_bits[i]; position += 1 }
			bits_length = position
		}
		result[0] = u8('0'); result[1] = u8('b'); result_length = 2
		sign := bits[0]
		if c.size_t(shift) >= bits_length {
			for i := c.size_t(0); i < bits_length; i += 1 { result[result_length] = sign; result_length += 1 }
		} else {
			for i := i64(0); i < shift; i += 1 { result[result_length] = sign; result_length += 1 }
			for i := c.size_t(0); i < bits_length - c.size_t(shift); i += 1 { result[result_length] = bits[i]; result_length += 1 }
		}
	}
	if output == nil || output_capacity < result_length do return -2
	for i := c.size_t(0); i < result_length; i += 1 { output[i] = result[i] }
	return i64(result_length)
}
