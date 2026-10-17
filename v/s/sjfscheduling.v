module sjfscheduling

const max_input_length = 130
const max_processes = 64
const max_output_bytes = 256

fn write_i32_le(mut output &u8, offset int, value i32) {
	unsafe {
		mut bits := u32(value)
		for byte in 0 .. 4 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'sjfscheduling']
pub fn sjfscheduling(input &i32, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_length) { return -1 }
		process_count_value := input[0]
		if process_count_value < 0 || process_count_value > max_processes || length != usize(1 + 2 * process_count_value) { return -1 }
		process_count := int(process_count_value)
		mut arrivals := [max_processes]i32{}
		mut bursts := [max_processes]i32{}
		mut order := [max_processes]i32{}
		mut completed := [max_processes]bool{}
		mut cursor := 1
		for index in 0 .. process_count {
			arrival, burst := input[cursor], input[cursor + 1]
			cursor += 2
			if arrival < 0 || arrival > 255 || burst < 1 || burst > 255 { return -1 }
			arrivals[index], bursts[index] = arrival, burst
		}

		mut current_time := i32(0)
		mut scheduled := 0
		for scheduled < process_count {
			mut best := process_count
			for index in 0 .. process_count {
				if completed[index] || arrivals[index] > current_time { continue }
				if best == process_count || bursts[index] < bursts[best] ||
					(bursts[index] == bursts[best] &&
					 (arrivals[index] < arrivals[best] ||
					  (arrivals[index] == arrivals[best] && index < best))) {
					best = index
				}
			}
			if best == process_count {
				current_time++
			} else {
				order[scheduled] = i32(best)
				scheduled++
				completed[best] = true
				current_time += bursts[best]
			}
		}

		output_bytes := process_count * 4
		if output == nil || capacity < usize(output_bytes) || output_bytes > max_output_bytes { return -2 }
		for index in 0 .. process_count { write_i32_le(mut output, index * 4, order[index]) }
		return i64(output_bytes)
	}
}
