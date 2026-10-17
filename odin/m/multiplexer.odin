package multiplexer

import "core:c"

@(export)
multiplexer :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 3 do return -1
	input0 := values[0]
	input1 := values[1]
	select := values[2]
	if (input0 != 0 && input0 != 1) || (input1 != 0 && input1 != 1) ||
		(select != 0 && select != 1) do return -1
	if select == 1 do return input1
	return input0
}
