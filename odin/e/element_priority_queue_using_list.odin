package element_priority_queue_using_list

import "core:c"

store_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u32(8*byte)) & 255) }
}

@(export)
element_priority_queue_using_list :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 514 do return -1
	operation_count := input[0]
	if operation_count < 0 || operation_count > 256 || int(length) != 1 + 2*int(operation_count) do return -1
	queue: [100]i32
	queue_count := 0
	dequeued: [128]i64
	dequeued_count := 0
	for i := 0; i < int(operation_count); i += 1 {
		opcode, argument := input[1+2*i], input[2+2*i]
		if opcode == 0 {
			if argument < -2147483648 || argument > 2147483647 || queue_count == 100 do return -1
			queue[queue_count] = i32(argument)
			queue_count += 1
		} else if opcode == 1 {
			if argument != 0 || queue_count == 0 do return -1
			minimum := 0
			for j := 1; j < queue_count; j += 1 { if queue[j] < queue[minimum] do minimum = j }
			dequeued[dequeued_count] = i64(queue[minimum])
			dequeued_count += 1
			queue_count -= 1
			for j := minimum; j < queue_count; j += 1 { queue[j] = queue[j+1] }
		} else do return -1
	}
	output_bytes := dequeued_count * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for i := 0; i < dequeued_count; i += 1 { store_i64(output, i*8, dequeued[i]) }
	return i64(output_bytes)
}
