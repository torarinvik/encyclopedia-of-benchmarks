package tbc_padding

import "core:c"

MAX_BYTES :: 256

write_i64_le :: proc(output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[position + byte] = u8(bits >> (8 * byte))
	}
}

@(export)
tbc_padding :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_BYTES + 3 do return -1
	operation, offset_value, count_value := input[0], input[1], input[2]
	if operation < 0 || operation > 2 || count_value < 0 || count_value > MAX_BYTES || length != c.size_t(count_value + 3) do return -1
	count := int(count_value)
	if (operation == 0 && (count == 0 || offset_value < 0 || offset_value > count_value)) ||
		(operation != 0 && offset_value != 0) || (operation == 2 && count == 0) do return -1
	for index := 0; index < count; index += 1 {
		if input[3 + index] < 0 || input[3 + index] > 255 do return -1
	}

	if operation == 0 {
		offset := int(offset_value)
		previous := input[count + 2]
		if offset > 0 do previous = input[offset + 2]
		code := if (previous & 1) == 0 then u8(0xff) else u8(0)
		needed := 8 + count
		if output == nil || capacity < c.size_t(needed) do return -2
		write_i64_le(output, 0, i64(count - offset))
		for index := 0; index < count; index += 1 {
			output[8 + index] = if index >= offset then code else u8(input[3 + index])
		}
		return i64(needed)
	}
	if operation == 1 {
		survivors := count
		if count > 0 {
			code := if (input[2 + count] & 1) == 0 then i64(0) else i64(255)
			for survivors > 0 && input[2 + survivors] == code { survivors -= 1 }
		}
		if output == nil || capacity < c.size_t(survivors) do return -2
		for index := 0; index < survivors; index += 1 { output[index] = u8(input[3 + index]) }
		return i64(survivors)
	}
	terminal := input[2 + count]
	if terminal != 0 && terminal != 255 do return -1
	padding_count := 0
	for padding_count < count && input[2 + count - padding_count] == terminal { padding_count += 1 }
	if output == nil || capacity < 8 do return -2
	write_i64_le(output, 0, i64(padding_count))
	return 8
}
