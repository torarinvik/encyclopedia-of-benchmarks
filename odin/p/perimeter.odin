package perimeter

import "core:c"

@(export)
perimeter :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	sides := values[0]
	side_length := values[1]
	if sides < 3 || sides > 256 || side_length < 1 || side_length > 255 do return -1
	return sides * side_length
}
