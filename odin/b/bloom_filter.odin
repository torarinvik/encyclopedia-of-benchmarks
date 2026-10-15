package bloom_filter

import "core:c"

MAX_TRACE_VALUES :: 256
MAX_KEY :: i64(1_000_000_000)

@(export)
bloom_filter :: proc "c" (trace: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_TRACE_VALUES || length % 2 != 0 do return -1
	query_count := c.size_t(0)
	for index := c.size_t(0); index < length; index += 2 {
		operation := trace[index]
		key := trace[index + 1]
		if (operation != 1 && operation != 2) || key < 0 || key > MAX_KEY do return -1
		if operation == 2 do query_count += 1
	}
	if output_capacity < query_count do return -2

	bits := u64(0)
	written := c.size_t(0)
	for index := c.size_t(0); index < length; index += 2 {
		key := trace[index + 1]
		first := u32((key * 17 + 3) % 64)
		second := u32((key * 31 + 7) % 64)
		first_mask := u64(1) << first
		second_mask := u64(1) << second
		if trace[index] == 1 {
			bits |= first_mask | second_mask
		} else {
			present := (bits & first_mask) != 0 && (bits & second_mask) != 0
			if present do output[written] = 1 else do output[written] = 0
			written += 1
		}
	}
	return i64(written)
}
