package nimply_gate

import "core:c"

@(export)
nimply_gate :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	a := values[0]
	b := values[1]
	if (a != 0 && a != 1) || (b != 0 && b != 1) do return -1
	if a == 1 && b == 0 do return 1
	return 0
}
