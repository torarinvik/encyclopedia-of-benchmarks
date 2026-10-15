package arithmetic_progression

import "core:c"

// Sum an inclusive arithmetic progression from packed [from, to, step].
@(export)
arithmetic_progression :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 3 do return -1
	from, to, step := values[0], values[1], values[2]
	if from < -1000000 || from > 1000000 || to < -1000000 || to > 1000000 do return -1
	if step < -1000000 || step > 1000000 || step == 0 do return -1
	if (from < to && step < 0) || (from > to && step > 0) do return -1
	count := (to - from) / step
	last := from + count * step
	return ((count + 1) * (from + last)) / 2
}
