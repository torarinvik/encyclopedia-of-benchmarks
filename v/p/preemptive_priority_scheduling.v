const max_processes = 8
const max_schedule_ticks = 80

fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'preemptive_priority_scheduling']
pub fn preemptive_priority_scheduling(input &i32, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if isnil(input) || length < 1 || length > 33 { return -1 }
		process_count := input[0]
		if process_count < 0 || process_count > max_processes || length != usize(1 + 4 * process_count) { return -1 }

		mut ids := [8]i32{}
		mut arrivals := [8]i32{}
		mut remaining := [8]i32{}
		mut priorities := [8]i32{}
		mut seen_ids := [8]bool{}
		for i := 0; i < int(process_count); i++ {
			offset := 1 + 4 * i
			id := input[offset]
			arrival := input[offset + 1]
			burst := input[offset + 2]
			priority := input[offset + 3]
			if id < 0 || id >= max_processes || seen_ids[id] || arrival < 0 || arrival > 16 || burst < 1 || burst > 8 { return -1 }
			for previous := 0; previous < i; previous++ {
				if priorities[previous] == priority && arrivals[previous] == arrival { return -1 }
			}
			seen_ids[id] = true
			ids[i] = id
			arrivals[i] = arrival
			remaining[i] = burst
			priorities[i] = priority
		}

		mut schedule := [max_schedule_ticks]i32{}
		mut tick_count := 0
		mut completed := 0
		for completed < int(process_count) {
			mut best := int(process_count)
			for i := 0; i < int(process_count); i++ {
				if remaining[i] <= 0 || arrivals[i] > tick_count { continue }
				if best == int(process_count) || priorities[i] > priorities[best] ||
					(priorities[i] == priorities[best] && arrivals[i] < arrivals[best]) { best = i }
			}
			if best == int(process_count) {
				schedule[tick_count] = -1
			} else {
				schedule[tick_count] = ids[best]
				remaining[best]--
				if remaining[best] == 0 { completed++ }
			}
			tick_count++
		}

		bytes := (1 + tick_count) * 4
		if isnil(output) || capacity < usize(bytes) { return -2 }
		mut buffer := [81 * 4]u8{}
		put_i32_le(mut buffer, 0, i32(tick_count))
		for i := 0; i < tick_count; i++ { put_i32_le(mut buffer, 4 * (i + 1), schedule[i]) }
		for i := 0; i < bytes; i++ { output[i] = buffer[i] }
		return i64(bytes)
	}
}
