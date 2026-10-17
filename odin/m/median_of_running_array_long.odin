package median_of_running_array_long

import "core:c"

MAX_COUNT :: 64
MAX_INPUT_LENGTH :: 66
MIN_SAMPLE :: i64(-4611686018427387904)
MAX_SAMPLE :: i64(4611686018427387903)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits >> u32(8*byte)) & 255) }
}
push_max :: proc "contextless" (heap: [^]i64, count: ^int, value: i64) {
	position := count^; count^ += 1
	for position > 0 && heap[(position-1)/2] < value { parent := (position-1)/2; heap[position] = heap[parent]; position = parent }
	heap[position] = value
}
pop_max :: proc "contextless" (heap: [^]i64, count: ^int) -> i64 {
	result := heap[0]; count^ -= 1; value := heap[count^]
	if count^ == 0 do return result
	position := 0
	for 2*position+1 < count^ { child := 2*position+1; if child+1 < count^ && heap[child+1] > heap[child] do child += 1; if heap[child] <= value do break; heap[position] = heap[child]; position = child }
	heap[position] = value; return result
}
push_min :: proc "contextless" (heap: [^]i64, count: ^int, value: i64) {
	position := count^; count^ += 1
	for position > 0 && heap[(position-1)/2] > value { parent := (position-1)/2; heap[position] = heap[parent]; position = parent }
	heap[position] = value
}
pop_min :: proc "contextless" (heap: [^]i64, count: ^int) -> i64 {
	result := heap[0]; count^ -= 1; value := heap[count^]
	if count^ == 0 do return result
	position := 0
	for 2*position+1 < count^ { child := 2*position+1; if child+1 < count^ && heap[child+1] < heap[child] do child += 1; if heap[child] >= value do break; heap[position] = heap[child]; position = child }
	heap[position] = value; return result
}

@(export)
median_of_running_array_long :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	count_value := input[0]
	if count_value < 1 || count_value > MAX_COUNT || int(length) != 1 + int(count_value) do return -1
	count := int(count_value)
	lower, upper, medians: [MAX_COUNT]i64
	lower_count, upper_count := 0, 0
	for i := 0; i < count; i += 1 {
		sample := input[i+1]
		if sample < MIN_SAMPLE || sample > MAX_SAMPLE do return -1
		if upper_count > 0 && sample < upper[0] do push_max(&lower[0], &lower_count, sample)
		else do push_min(&upper[0], &upper_count, sample)
		if lower_count > upper_count+1 do push_min(&upper[0], &upper_count, pop_max(&lower[0], &lower_count))
		else if upper_count > lower_count+1 do push_max(&lower[0], &lower_count, pop_min(&upper[0], &upper_count))
		if lower_count > upper_count do medians[i] = lower[0]
		else if upper_count > lower_count do medians[i] = upper[0]
		else do medians[i] = (lower[0] + upper[0]) / 2
	}
	output_bytes := count * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for i := 0; i < count; i += 1 { store_i64_le(output, 8*i, medians[i]) }
	return i64(output_bytes)
}
