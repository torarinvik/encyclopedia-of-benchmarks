package hampel_filter

import "core:c"

insert_sorted :: proc "contextless" (values: [^]f64, size: ^int, value: f64) {
	position := 0
	for position < size^ && values[position] < value { position += 1 }
	for index := size^; index > position; index -= 1 { values[index] = values[index - 1] }
	values[position] = value
	size^ += 1
}

median :: proc "contextless" (values: [^]f64, size: int) -> f64 {
	middle := size / 2
	if size % 2 == 1 do return values[middle]
	return 0.5 * (values[middle - 1] + values[middle])
}

median_absolute_deviation :: proc "contextless" (sorted: [^]f64, size: int, center: f64) -> f64 {
	deviations: [3]f64
	deviation_count := 0
	for index := 0; index < size; index += 1 {
		difference := sorted[index] - center
		if difference < 0 do difference = -difference
		insert_sorted(&deviations[0], &deviation_count, difference)
	}
	return median(&deviations[0], deviation_count)
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}

@(export)
hampel_filter :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || input[0] < 0 || input[0] > 128 do return -1
	n := int(input[0])
	if length != c.size_t(n + 1) do return -1
	for index := 0; index < n; index += 1 {
		if input[index + 1] < -1000 || input[index + 1] > 1000 do return -1
	}
	if capacity < c.size_t(n * 8) || (n > 0 && output == nil) do return -2

	arrival: [3]f64
	sorted: [3]f64
	size := 0
	oldest := 0
	for index := 0; index < n; index += 1 {
		value := f64(input[index + 1])
		if size == 3 {
			position := 0
			for position < size && sorted[position] != arrival[oldest] { position += 1 }
			if position < size {
				for cursor := position + 1; cursor < size; cursor += 1 { sorted[cursor - 1] = sorted[cursor] }
				size -= 1
			}
		}
		insert_sorted(&sorted[0], &size, value)
		arrival[oldest] = value
		oldest = (oldest + 1) % 3

		center := median(&sorted[0], size)
		deviation := median_absolute_deviation(&sorted[0], size, center)
		distance := value - center
		if distance < 0 do distance = -distance
		filtered := value
		if distance > 3.0 * 1.4826 * deviation do filtered = center
		put_i64_le(output, index * 8, i64(filtered))
	}
	return i64(n * 8)
}
