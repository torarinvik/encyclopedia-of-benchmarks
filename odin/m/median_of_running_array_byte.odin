package median_of_running_array_byte

import "core:c"

push_max :: proc "contextless" (heap: [^]i32, count: ^int, value: i32) {
	i := count^; count^ += 1
	for i > 0 && heap[(i-1)/2] < value { parent := (i-1)/2; heap[i] = heap[parent]; i = parent }
	heap[i] = value
}
pop_max :: proc "contextless" (heap: [^]i32, count: ^int) -> i32 {
	result := heap[0]; count^ -= 1; value := heap[count^]
	if count^ == 0 do return result
	i := 0
	for 2*i+1 < count^ { child := 2*i+1; if child+1 < count^ && heap[child+1] > heap[child] do child += 1; if heap[child] <= value do break; heap[i] = heap[child]; i = child }
	heap[i] = value; return result
}
push_min :: proc "contextless" (heap: [^]i32, count: ^int, value: i32) {
	i := count^; count^ += 1
	for i > 0 && heap[(i-1)/2] > value { parent := (i-1)/2; heap[i] = heap[parent]; i = parent }
	heap[i] = value
}
pop_min :: proc "contextless" (heap: [^]i32, count: ^int) -> i32 {
	result := heap[0]; count^ -= 1; value := heap[count^]
	if count^ == 0 do return result
	i := 0
	for 2*i+1 < count^ { child := 2*i+1; if child+1 < count^ && heap[child+1] < heap[child] do child += 1; if heap[child] >= value do break; heap[i] = heap[child]; i = child }
	heap[i] = value; return result
}

@(export)
median_of_running_array_byte :: proc "c" (input: [^]i32, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 66 do return -1
	count_value := input[0]
	if count_value < 1 || count_value > 64 || int(length) != 1 + int(count_value) do return -1
	count := int(count_value)
	lower, upper: [64]i32
	medians: [64]u8
	lower_count, upper_count := 0, 0
	for i := 0; i < count; i += 1 {
		sample := input[i+1]
		if sample < -128 || sample > 127 do return -1
		if upper_count > 0 && sample < upper[0] do push_max(&lower[0], &lower_count, sample)
		else do push_min(&upper[0], &upper_count, sample)
		if lower_count > upper_count+1 do push_min(&upper[0], &upper_count, pop_max(&lower[0], &lower_count))
		else if upper_count > lower_count+1 do push_max(&lower[0], &lower_count, pop_min(&upper[0], &upper_count))
		median: i32
		if lower_count > upper_count do median = lower[0]
		else if upper_count > lower_count do median = upper[0]
		else {
			sum := lower[0] + upper[0]
			if sum < 0 do median = -((-sum)/2) else do median = sum/2
		}
		medians[i] = u8(median & 255)
	}
	if output == nil || capacity < c.size_t(count) do return -2
	for i := 0; i < count; i += 1 { output[i] = medians[i] }
	return i64(count)
}
