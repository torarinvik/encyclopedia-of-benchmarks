package median_of_running_array_float

import "core:c"
import "core:math"

MAX_COUNT :: 64
MAX_INPUT_LENGTH :: 66

less_float :: proc "contextless" (left, right: f32) -> bool {
	if left < right do return true
	if left == 0.0 && right == 0.0 { return transmute(u32)left >> 31 != 0 && transmute(u32)right >> 31 == 0 }
	return false
}
push_max :: proc "contextless" (heap: [^]f32, count: ^int, value: f32) {
	position := count^; count^ += 1
	for position > 0 && less_float(heap[(position-1)/2], value) { parent := (position-1)/2; heap[position] = heap[parent]; position = parent }
	heap[position] = value
}
pop_max :: proc "contextless" (heap: [^]f32, count: ^int) -> f32 {
	result := heap[0]; count^ -= 1; value := heap[count^]
	if count^ == 0 do return result
	position := 0
	for 2*position+1 < count^ { child := 2*position+1; if child+1 < count^ && less_float(heap[child],heap[child+1]) do child += 1; if !less_float(value,heap[child]) do break; heap[position]=heap[child];position=child }
	heap[position]=value;return result
}
push_min :: proc "contextless" (heap: [^]f32, count: ^int, value: f32) {
	position := count^; count^ += 1
	for position > 0 && less_float(value, heap[(position-1)/2]) { parent := (position-1)/2; heap[position] = heap[parent]; position = parent }
	heap[position] = value
}
pop_min :: proc "contextless" (heap: [^]f32, count: ^int) -> f32 {
	result := heap[0]; count^ -= 1; value := heap[count^]
	if count^ == 0 do return result
	position := 0
	for 2*position+1 < count^ { child := 2*position+1; if child+1 < count^ && less_float(heap[child+1],heap[child]) do child += 1; if !less_float(heap[child],value) do break; heap[position]=heap[child];position=child }
	heap[position]=value;return result
}

@(export)
median_of_running_array_float :: proc "c" (input: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	count_value := input[0]
	if count_value != count_value || math.abs(count_value) > 1e308 || count_value < 1.0 || count_value > f64(MAX_COUNT) || f64(int(count_value)) != count_value || int(length) != 1 + int(count_value) do return -1
	count := int(count_value)
	lower, upper, medians: [MAX_COUNT]f32
	lower_count, upper_count := 0, 0
	for i := 0; i < count; i += 1 {
		sample := input[i+1]
		if sample != sample || math.abs(sample) > 1e308 || sample < -1000000.0 || sample > 1000000.0 do return -1
		x := f32(sample)
		if f64(x) != sample || (sample == 0.0 && (transmute(u64)sample >> 63) != u64(transmute(u32)x >> 31)) do return -1
		if upper_count > 0 && less_float(x, upper[0]) do push_max(&lower[0], &lower_count, x)
		else do push_min(&upper[0], &upper_count, x)
		if lower_count > upper_count+1 do push_min(&upper[0], &upper_count, pop_max(&lower[0], &lower_count))
		else if upper_count > lower_count+1 do push_max(&lower[0], &lower_count, pop_min(&upper[0], &upper_count))
		if lower_count > upper_count do medians[i] = lower[0]
		else if upper_count > lower_count do medians[i] = upper[0]
		else { sum: f32 = lower[0] + upper[0]; average: f32 = sum / 2.0; medians[i] = average }
	}
	if output == nil || capacity < c.size_t(count) do return -2
	for i := 0; i < count; i += 1 { output[i] = f64(medians[i]) }
	return i64(count)
}
