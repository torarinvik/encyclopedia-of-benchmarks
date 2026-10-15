package strobogrammatic_number

import "core:c"

MAX_INPUT_LENGTH :: 64

rotated_digit :: proc(value: i64) -> i64 {
	switch value {
	case 48: return 48
	case 49: return 49
	case 54: return 57
	case 56: return 56
	case 57: return 54
	}
	return -1
}

@(export)
strobogrammatic_number :: proc "c" (bytes: [^]i64, length: c.size_t) -> i64 {
	if (bytes == nil && length != 0) || length > MAX_INPUT_LENGTH do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if bytes[index] < 0 || bytes[index] > 127 do return -1
	}
	left := c.size_t(0)
	right := length
	for left < right {
		right -= 1
		if rotated_digit(bytes[left]) != bytes[right] do return 0
		left += 1
	}
	return 1
}
