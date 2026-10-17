package mutate

import "core:c"

MAX_GENES :: 64

@(export)
mutate :: proc "c" (input: [^]f64, length: c.size_t,
		output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 130 do return -1
	mu := input[0]
	count_value := input[1]
	if mu != mu || mu < 0.0 || mu > 1.0 do return -1
	if count_value != count_value || count_value < 0.0 || count_value > MAX_GENES || f64(i64(count_value)) != count_value do return -1
	count := int(count_value)
	if int(length) != 2 + 2 * count do return -1
	for index := 0; index < count; index += 1 {
		gene := input[2 + index]
		if gene != 0.0 && gene != 1.0 do return -1
	}
	for index := 0; index < count; index += 1 {
		draw := input[2 + count + index]
		if draw != draw || draw < 0.0 || draw >= 1.0 do return -1
	}
	if output == nil || capacity < c.size_t(count) do return -2
	for index := 0; index < count; index += 1 {
		gene := input[2 + index]
		draw := input[2 + count + index]
		if draw < mu do output[index] = 1.0 - gene else output[index] = gene
	}
	return i64(count)
}
