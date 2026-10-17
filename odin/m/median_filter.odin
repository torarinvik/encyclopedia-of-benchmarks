package median_filter

import "core:c"

MAX_WINDOW :: 16
MAX_SAMPLES :: 64

lower_bound :: proc "contextless" (sorted: [^]f64, size: int, value: f64) -> int {
	low := 0
	high := size
	for low < high {
		middle := low + (high - low) / 2
		if sorted[middle] < value do low = middle + 1 else high = middle
	}
	return low
}

@(export)
median_filter :: proc "c" (input: [^]f64, length: c.size_t,
		output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 66 do return -1
	window_value := input[0]
	count_value := input[1]
	if window_value != window_value || window_value < 1 || window_value > MAX_WINDOW || f64(i64(window_value)) != window_value do return -1
	if count_value != count_value || count_value < 0 || count_value > MAX_SAMPLES || f64(i64(count_value)) != count_value do return -1
	window := int(window_value)
	count := int(count_value)
	if int(length) != 2 + count do return -1
	samples: [MAX_SAMPLES]f64
	for index := 0; index < count; index += 1 {
		value := input[2 + index]
		if value != value || value < -1000000.0 || value > 1000000.0 do return -1
		samples[index] = value
	}
	if output == nil || capacity < c.size_t(count) do return -2

	arrival: [MAX_WINDOW]f64
	sorted: [MAX_WINDOW]f64
	result: [MAX_SAMPLES]f64
	size := 0
	oldest := 0
	for index := 0; index < count; index += 1 {
		value := samples[index]
		if size == window {
			position := lower_bound(&sorted[0], size, arrival[oldest])
			for shift := position + 1; shift < size; shift += 1 do sorted[shift - 1] = sorted[shift]
			size -= 1
		}
		position := lower_bound(&sorted[0], size, value)
		shift := size
		for shift > position { sorted[shift] = sorted[shift - 1]; shift -= 1 }
		sorted[position] = value
		arrival[oldest] = value
		oldest = (oldest + 1) % window
		size += 1
		middle := size / 2
		if size % 2 != 0 do result[index] = sorted[middle]
		else do result[index] = 0.5 * (sorted[middle - 1] + sorted[middle])
	}
	for index := 0; index < count; index += 1 do output[index] = result[index]
	return i64(count)
}
