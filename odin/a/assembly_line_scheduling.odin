package assembly_line_scheduling

import "core:c"

// Minimum time to cross two assembly lines using station-by-station dynamic programming.
@(export)
assembly_line_scheduling :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 7 || values[0] < 1 || values[0] > 64 do return -1
	n := int(values[0])
	if int(length) != 4 * n + 3 do return -1
	for index := 0; index < int(length); index += 1 {
		if values[index] < 0 || values[index] > 1000 do return -1
	}

	a0 := 1
	a1 := a0 + n
	t0 := a1 + n
	t1 := t0 + n - 1
	entry := t1 + n - 1
	line0 := values[entry] + values[a0]
	line1 := values[entry + 1] + values[a1]
	for station := 1; station < n; station += 1 {
		stay0 := line0 + values[a0 + station]
		switch0 := line1 + values[t1 + station - 1] + values[a0 + station]
		stay1 := line1 + values[a1 + station]
		switch1 := line0 + values[t0 + station - 1] + values[a1 + station]
		line0 = min(stay0, switch0)
		line1 = min(stay1, switch1)
	}
	total0 := line0 + values[entry + 2]
	total1 := line1 + values[entry + 3]
	answer := min(total0, total1)
	if output == nil || output_capacity < 4 do return -2
	for byte := 0; byte < 4; byte += 1 {
		output[byte] = u8((answer >> (8 * byte)) & 255)
	}
	return 4
}
