package preemptive_priority_scheduling

import "core:c"

MAX_PROCESSES :: 8
MAX_SCHEDULE_TICKS :: 80
MAX_OUTPUT_WORDS :: 81

put_i32_le :: proc(output: [^]u8, offset: int, value: i32) {
	bits := transmute(u32)value
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8(bits >> u32(8 * byte))
	}
}

@(export)
preemptive_priority_scheduling :: proc "c" (input: [^]i32, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 33 do return -1
	process_count := input[0]
	if process_count < 0 || process_count > MAX_PROCESSES do return -1
	if length != c.size_t(1 + 4 * process_count) do return -1

	ids: [MAX_PROCESSES]i32 = {}
	arrivals: [MAX_PROCESSES]i32 = {}
	remaining: [MAX_PROCESSES]i32 = {}
	priorities: [MAX_PROCESSES]i32 = {}
	seen_ids: [MAX_PROCESSES]bool = {}
	for i in 0..<int(process_count) {
		offset := 1 + 4 * i
		id := input[offset]
		arrival := input[offset + 1]
		burst := input[offset + 2]
		priority := input[offset + 3]
		if id < 0 || id >= MAX_PROCESSES || seen_ids[int(id)] || arrival < 0 || arrival > 16 || burst < 1 || burst > 8 do return -1
		for previous in 0..<i {
			if priorities[previous] == priority && arrivals[previous] == arrival do return -1
		}
		seen_ids[int(id)] = true
		ids[i] = id
		arrivals[i] = arrival
		remaining[i] = burst
		priorities[i] = priority
	}

	schedule: [MAX_SCHEDULE_TICKS]i32 = {}
	tick_count := 0
	completed := 0
	for completed < int(process_count) {
		best := int(process_count)
		for i in 0..<int(process_count) {
			if remaining[i] <= 0 || arrivals[i] > i32(tick_count) do continue
			if best == int(process_count) || priorities[i] > priorities[best] ||
				(priorities[i] == priorities[best] && arrivals[i] < arrivals[best]) {
				best = i
			}
		}
		if best == int(process_count) {
			schedule[tick_count] = -1
		} else {
			schedule[tick_count] = ids[best]
			remaining[best] -= 1
			if remaining[best] == 0 { completed += 1 }
		}
		tick_count += 1
	}

	bytes := (1 + tick_count) * 4
	if output == nil || capacity < c.size_t(bytes) do return -2
	buffer: [MAX_OUTPUT_WORDS * 4]u8 = {}
	put_i32_le(raw_data(buffer[:]), 0, i32(tick_count))
	for i in 0..<tick_count { put_i32_le(raw_data(buffer[:]), 4 * (i + 1), schedule[i]) }
	for i in 0..<bytes { output[i] = buffer[i] }
	return i64(bytes)
}
