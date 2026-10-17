package fixed_priority_queue_using_list

import "core:c"

store_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u32(8*byte)) & 255) }
}

@(export)
fixed_priority_queue_using_list :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 770 do return -1
	operation_count := input[0]
	if operation_count < 0 || operation_count > 256 || int(length) != 1 + 3*int(operation_count) do return -1
	buckets: [3][100]i32
	counts: [3]int
	dequeued: [128]i64
	dequeued_count := 0
	for i := 0; i < int(operation_count); i += 1 {
		opcode, priority, data := input[1+3*i], input[2+3*i], input[3+3*i]
		if opcode == 0 {
			if priority < -3 || priority > 2 || data < -2147483648 || data > 2147483647 do return -1
			bucket := int(if priority < 0 do priority+3 else priority)
			if counts[bucket] == 100 do return -1
			buckets[bucket][counts[bucket]] = i32(data)
			counts[bucket] += 1
		} else if opcode == 1 {
			if priority != 0 || data != 0 do return -1
			bucket := 0
			for bucket < 3 && counts[bucket] == 0 { bucket += 1 }
			if bucket == 3 do return -1
			dequeued[dequeued_count] = i64(buckets[bucket][0])
			dequeued_count += 1
			counts[bucket] -= 1
			for j := 0; j < counts[bucket]; j += 1 { buckets[bucket][j] = buckets[bucket][j+1] }
		} else do return -1
	}
	output_bytes := dequeued_count * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for i := 0; i < dequeued_count; i += 1 { store_i64(output, i*8, dequeued[i]) }
	return i64(output_bytes)
}
