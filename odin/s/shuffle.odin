package shuffle

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 513
MAX_LENGTH :: 256

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

@(export)
shuffle :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 0, MAX_LENGTH) do return -1
	count := int(input[0])
	offset_count := 0
	if count > 0 { offset_count = count - 1 }
	if int(input_length) != 1 + count + offset_count do return -1

	items: [MAX_LENGTH]i32
	for index := 0; index < count; index += 1 {
		value := input[index+1]
		if !exact_integer(value, -2147483648, 2147483647) do return -1
		items[index] = i32(value)
	}
	offsets: [MAX_LENGTH]int
	for index := 0; index < offset_count; index += 1 {
		value := input[1+count+index]
		if !exact_integer(value, 0, i64(count-1-index)) do return -1
		offsets[index] = int(value)
	}
	for index := 0; index < offset_count; index += 1 {
		other := index + offsets[index]
		items[index], items[other] = items[other], items[index]
	}

	if output == nil || capacity < c.size_t(count) do return -2
	for index := 0; index < count; index += 1 { output[index] = f64(items[index]) }
	return i64(count)
}
