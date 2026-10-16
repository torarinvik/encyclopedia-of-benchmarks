package recursive_shuffler

import "core:c"
import "core:runtime"

MODULUS :: u64(2_147_483_647)

shuffle_recursive :: proc(values: [^]i32, item: int, state: ^u64) {
	if item <= 0 do return
	shuffle_recursive(values, item - 1, state)
	state^ = (state^ * 48_271) % MODULUS
	other := int(state^ % u64(item + 1))
	temporary := values[item]
	values[item] = values[other]
	values[other] = temporary
}

@(export)
recursive_shuffler :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	context = runtime.default_context()
	MAX_VALUES :: 64
	if input == nil || length < 1 || length > c.size_t(MAX_VALUES + 1) do return -1
	seed := input[0]
	if seed < 1 || seed >= 2_147_483_647 do return -1
	count := int(length - 1)
	values: [MAX_VALUES]i32
	for index := 0; index < count; index += 1 {
		value := input[index + 1]
		if value < -2_147_483_648 || value > 2_147_483_647 do return -1
		values[index] = i32(value)
	}
	byte_count := c.size_t(count * 4)
	if output_capacity < byte_count || (byte_count != 0 && output == nil) do return -2
	state := u64(seed)
	if count > 1 do shuffle_recursive(&values[0], count - 1, &state)
	for index := 0; index < count; index += 1 {
		bits := u32(values[index])
		for byte := 0; byte < 4; byte += 1 {
			output[index*4+byte] = u8((bits >> u32(byte*8)) & 255)
		}
	}
	return i64(count)
}
