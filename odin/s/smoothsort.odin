package smoothsort

import "core:c"

MAX_COUNT :: 64
MAX_INPUT_LENGTH :: 66

sift :: proc "contextless" (values: [^]i64, root_arg, order_arg: int, leonardo: [^]int) {
	root, order := root_arg, order_arg
	for order > 1 {
		right := root - 1; left := root - 1 - leonardo[order-2]
		if !(values[left] < values[right]) && values[root] < values[left] {
			values[root], values[left] = values[left], values[root]; root = left; order -= 1
		} else if values[left] < values[right] && values[root] < values[right] {
			values[root], values[right] = values[right], values[root]; root = right; order -= 2
		} else { break }
	}
}
trinkle :: proc "contextless" (values: [^]i64, position_arg: int, orders: [^]int, index_arg: int, leonardo: [^]int) {
	position, index := position_arg, index_arg
	for index > 0 {
		previous := position - leonardo[orders[index]]
		if !(values[position] < values[previous]) { break }
		if orders[index] > 1 {
			right := position - 1; left := position - 1 - leonardo[orders[index]-2]
			if !(values[right] < values[previous]) || !(values[left] < values[previous]) { break }
		}
		values[position], values[previous] = values[previous], values[position]; position = previous; index -= 1
	}
	sift(values, position, orders[index], leonardo)
}
smooth_sort :: proc "contextless" (values: [^]i64, count: int) {
	if count < 2 do return
	leonardo: [16]int; leonardo[0] = 1; leonardo[1] = 1
	for i := 2; i < 16; i += 1 { leonardo[i] = leonardo[i-1] + leonardo[i-2] + 1 }
	orders: [MAX_COUNT]int; heap_count := 0
	for position := 0; position < count; position += 1 {
		if heap_count >= 2 && orders[heap_count-2] == orders[heap_count-1]+1 { heap_count -= 1; orders[heap_count-1] += 1
		} else if heap_count > 0 && orders[heap_count-1] == 1 { orders[heap_count] = 0; heap_count += 1
		} else { orders[heap_count] = 1; heap_count += 1 }
		trinkle(values, position, &orders[0], heap_count-1, &leonardo[0])
	}
	for position := count - 1; position >= 0; position -= 1 {
		heap_count -= 1; order := orders[heap_count]
		if order > 1 {
			right_order := order - 2; left_order := order - 1
			right_position := position - 1; left_position := position - 1 - leonardo[right_order]
			orders[heap_count] = left_order; heap_count += 1; trinkle(values, left_position, &orders[0], heap_count-1, &leonardo[0])
			orders[heap_count] = right_order; heap_count += 1; trinkle(values, right_position, &orders[0], heap_count-1, &leonardo[0])
		}
	}
}
store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u32(8*byte)) }
}

@(export)
smoothsort :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 0 || input[0] > i64(MAX_COUNT) do return -1
	count := int(input[0])
	if int(length) != 1+count || length > c.size_t(MAX_COUNT+1) do return -1
	values: [MAX_COUNT]i64
	for i := 0; i < count; i += 1 { values[i] = input[i+1] }
	smooth_sort(&values[0], count)
	bytes := count*8
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i := 0; i < count; i += 1 { store_i64_le(output, i*8, values[i]) }
	return i64(bytes)
}
