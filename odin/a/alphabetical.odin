package alphabetical

import "core:c"

is_ascii_letter :: proc "contextless" (value: i64) -> bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

lowercase_ascii :: proc "contextless" (value: i64) -> i64 {
	if value >= 65 && value <= 90 do return value + 32
	return value
}

@(export)
alphabetical :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 256 || (length != 0 && values == nil) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] < 0 || values[index] > 127 do return -1
	}
	if length == 0 do return 0
	previous := i64(-1)
	for index := c.size_t(0); index < length; index += 1 {
		value := values[index]
		if !is_ascii_letter(value) do return 0
		current := lowercase_ascii(value)
		if current < previous do return 0
		previous = current
	}
	return 1
}
