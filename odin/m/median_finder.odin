package median_finder

import "core:c"

heap_push :: proc(heap: ^([32]i64), size: ^int, is_max: bool, value: i64) {
	index := size^
	size^ += 1
	heap^[index] = value
	for index > 0 {
		parent := (index - 1) / 2
		ordered := if is_max { heap^[parent] >= heap^[index] } else { heap^[parent] <= heap^[index] }
		if ordered do break
		heap^[parent], heap^[index] = heap^[index], heap^[parent]
		index = parent
	}
}

heap_pop :: proc(heap: ^([32]i64), size: ^int, is_max: bool) -> i64 {
	result := heap^[0]
	size^ -= 1
	heap^[0] = heap^[size^]
	index := 0
	for {
		left := 2 * index + 1
		right := left + 1
		best := index
		if left < size^ {
			if if is_max { heap^[left] > heap^[best] } else { heap^[left] < heap^[best] } { best = left }
		}
		if right < size^ {
			if if is_max { heap^[right] > heap^[best] } else { heap^[right] < heap^[best] } { best = right }
		}
		if best == index do break
		heap^[index], heap^[best] = heap^[best], heap^[index]
		index = best
	}
	return result
}

write_f64_le :: proc(output: [^]u8, position: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[position + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
median_finder :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 65 do return -1
	count_value := input[0]
	if count_value < 1 || count_value > 64 || length != c.size_t(count_value + 1) do return -1
	count := int(count_value)
	for index := 0; index < count; index += 1 {
		if input[index + 1] < -1_000_000 || input[index + 1] > 1_000_000 do return -1
	}
	required := c.size_t(count * 8)
	if output == nil || output_capacity < required do return -2

	var lower: [32]i64
	var upper: [32]i64
	lower_size := 0
	upper_size := 0
	for index := 0; index < count; index += 1 {
		value := input[index + 1]
		if lower_size == 32 && lower_size > upper_size && value <= lower[0] {
			heap_push(&upper, &upper_size, false, heap_pop(&lower, &lower_size, true))
			heap_push(&lower, &lower_size, true, value)
		} else {
			if lower_size == 0 || value <= lower[0] {
				heap_push(&lower, &lower_size, true, value)
			} else {
				heap_push(&upper, &upper_size, false, value)
			}
			if lower_size > upper_size + 1 {
				heap_push(&upper, &upper_size, false, heap_pop(&lower, &lower_size, true))
			} else if upper_size > lower_size {
				heap_push(&lower, &lower_size, true, heap_pop(&upper, &upper_size, false))
			}
		}
		median := if lower_size == upper_size {
			(f64(lower[0]) + f64(upper[0])) / 2.0
		} else {
			f64(lower[0])
		}
		write_f64_le(output, index * 8, median)
	}
	return i64(required)
}
