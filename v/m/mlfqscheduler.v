module mlfqscheduler

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'mlfqscheduler']
pub fn mlfqscheduler(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if input == nil || length < 2 || length > 55 { return -1 }
	levels_value := unsafe { input[0] }
	process_count_value := unsafe { input[1] }
	if levels_value < 1 || levels_value > 4 || process_count_value < 0 || process_count_value > 16 { return -1 }
	levels := int(levels_value)
	process_count := int(process_count_value)
	if length != usize(2 + levels + 3 * process_count) { return -1 }
	mut quanta := [4]i64{}
	mut pids := [16]i64{}
	mut remaining := [16]i64{}
	for level in 0 .. levels {
		quanta[level] = unsafe { input[2 + level] }
		if quanta[level] < 1 || quanta[level] > 32 { return -1 }
	}
	process_offset := 2 + levels
	for i in 0 .. process_count {
		pid := unsafe { input[process_offset + 3 * i] }
		burst := unsafe { input[process_offset + 3 * i + 1] }
		arrival := unsafe { input[process_offset + 3 * i + 2] }
		if pid < -2147483648 || pid > 2147483647 || burst < 0 || burst > 1000 || arrival < 0 || arrival > 1000000 { return -1 }
		pids[i] = pid
		remaining[i] = burst
	}

	mut queues := [64]int{}
	mut queue_counts := [4]int{}
	for i in 0 .. process_count { queues[i] = i }
	queue_counts[0] = process_count
	mut completion_pids := [16]i64{}
	mut completion_times := [16]i64{}
	mut completions := 0
	mut current_time := i64(0)
	mut running := true
	for running {
		mut active := 0
		for level in 0 .. levels { active += queue_counts[level] }
		if active == 0 { running = false; continue }
		for level in 0 .. levels {
			base := level * 16
			queued := queue_counts[level]
			if queued == 0 { continue }
			process := queues[base]
			mut j := 1
			for j < queued { queues[base + j - 1] = queues[base + j]; j++ }
			queue_counts[level]--
			mut slice := quanta[level]
			if remaining[process] < slice { slice = remaining[process] }
			current_time += slice
			remaining[process] -= slice
			if remaining[process] == 0 {
				completion_pids[completions] = pids[process]
				completion_times[completions] = current_time
				completions++
			} else {
				mut destination := level
				if level + 1 < levels { destination = level + 1 }
				queues[destination * 16 + queue_counts[destination]] = process
				queue_counts[destination]++
			}
		}
	}

	elements := 2 + 2 * completions
	required := elements * 8
	if output == nil || output_capacity < usize(required) { return -2 }
	unsafe {
		put_i64_le(mut output, 0, current_time)
		put_i64_le(mut output, 8, i64(completions))
		for i in 0 .. completions {
			put_i64_le(mut output, 16 + 16 * i, completion_pids[i])
			put_i64_le(mut output, 24 + 16 * i, completion_times[i])
		}
	}
	return i64(elements)
}
