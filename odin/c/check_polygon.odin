package check_polygon

import "core:c"

@(export)
check_polygon :: proc "c" (values: [^]i64, length: c.size_t,
		_output: [^]u8, _output_capacity: c.size_t) -> i64 {
	if values == nil || length < 3 || length > 256 do return -1
	total: i64 = 0
	maximum: i64 = 0
	for index := 0; index < int(length); index += 1 {
		side := values[index]
		if side < 1 || side > 1_000_000_000 do return -1
		total += side
		if side > maximum do maximum = side
	}
	if maximum < total - maximum do return 1
	return 0
}
