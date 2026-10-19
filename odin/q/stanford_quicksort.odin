package stanford_quicksort

import "core:c"

SORT_ELEMENTS :: 5000
MAX_PREFIX_COUNT :: i64(100)
MAX_OUTPUT_BYTES :: 700

source_quicksort :: proc(values: []i64, left_value, right_value: int) {
	left := left_value
	right := right_value
	i := left
	j := right
	pivot := values[(left + right) / 2]
	for {
		for values[i] < pivot { i += 1 }
		for pivot < values[j] { j -= 1 }
		if i <= j {
			temporary := values[i]
			values[i] = values[j]
			values[j] = temporary
			i += 1
			j -= 1
		}
		if i > j do break
	}
	if left < j do source_quicksort(values, left, j)
	if i < right do source_quicksort(values, i, right)
}

append_number :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, value_value: i64) {
	value := value_value
	if value < 0 {
		buffer[used^] = u8('-')
		used^ += 1
		value = -value
	}
	var reversed: [20]u8
	count := 0
	for {
		reversed[count] = u8('0') + u8(value % 10)
		count += 1
		value /= 10
		if value == 0 do break
	}
	for count > 0 {
		count -= 1
		buffer[used^] = reversed[count]
		used^ += 1
	}
	buffer[used^] = 10
	used^ += 1
}

@(export)
stanford_quicksort :: proc "c" (prefix_count: i64, output: [^]u8,
	output_capacity: c.size_t) -> i64 {
	if prefix_count < 1 || prefix_count > MAX_PREFIX_COUNT do return -1
	if output == nil do return -2

	var staged: [MAX_OUTPUT_BYTES]u8
	used := 0
	for run := i64(0); run < prefix_count; run += 1 {
		var values: [SORT_ELEMENTS + 1]i64
		state := i64(74755)
		for index := 1; index <= SORT_ELEMENTS; index += 1 {
			state = (state * 1309 + 13849) & 65535
			values[index] = state - 50000
		}
		source_quicksort(values[:], 1, SORT_ELEMENTS)
		append_number(&staged, &used, values[int(run + 1)])
	}

	if output_capacity < c.size_t(used) do return -2
	for index := 0; index < used; index += 1 do output[index] = staged[index]
	return i64(used)
}
