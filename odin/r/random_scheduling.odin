package random_scheduling

import "core:c"

MAX_TASK_COUNT :: 32
MAX_INPUT_LENGTH :: 35
MAX_OUTPUT_BYTES :: 256
JAVA_MULTIPLIER :: u64(0x5DEECE66D)
JAVA_ADDEND :: u64(0xB)
JAVA_MASK :: u64(0xFFFFFFFFFFFF)

Java_Random :: struct { state: u64 }

java_next_bits :: proc(random: ^Java_Random, bits: u32) -> u32 {
	random.state = (random.state * JAVA_MULTIPLIER + JAVA_ADDEND) & JAVA_MASK
	return u32(random.state >> (48 - bits))
}

java_next_int :: proc(random: ^Java_Random, bound: u32) -> u32 {
	if (bound & (bound - 1)) == 0 {
		return u32((u64(bound) * u64(java_next_bits(random, 31))) >> 31)
	}
	for {
		bits := java_next_bits(random, 31)
		value := bits % bound
		if u64(bits) - u64(value) + u64(bound - 1) <= u64(2147483647) do return value
	}
}

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
	}
}

@(export)
random_scheduling :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_INPUT_LENGTH do return -1
	if input[1] < 0 || input[1] > MAX_TASK_COUNT do return -1
	count := int(input[1])
	if input_length != c.size_t(count + 2) do return -1

	tasks: [MAX_TASK_COUNT]i64
	for index := 0; index < count; index += 1 {
		task := input[index + 2]
		if task < -2147483648 || task > 2147483647 do return -1
		tasks[index] = task
	}
	random := Java_Random{state = (u64(input[0]) ^ JAVA_MULTIPLIER) & JAVA_MASK}
	for size := count; size > 1; size -= 1 {
		selected := int(java_next_int(&random, u32(size)))
		saved := tasks[size - 1]
		tasks[size - 1] = tasks[selected]
		tasks[selected] = saved
	}

	output_bytes := count * 8
	if output_bytes > MAX_OUTPUT_BYTES do return -1
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < count; index += 1 { put_i64_le(output, index * 8, tasks[index]) }
	return i64(output_bytes)
}
