fn next_java_state(state u64) u64 {
	low := state & u64(0xffffff)
	high := state >> 24
	low_product := low * u64(0x5deece66d)
	high_product := (high * u64(0x5deece66d)) & u64(0xffffff)
	return (low_product + (high_product << 24) + u64(0xb)) & ((u64(1) << 48) - 1)
}

fn java_next_int(mut state &u64, bound u64) u64 {
	if (bound & (bound - 1)) == 0 {
		state[0] = next_java_state(state[0])
		return (bound * (state[0] >> 17)) >> 31
	}
	for {
		state[0] = next_java_state(state[0])
		bits := state[0] >> 17
		value := bits % bound
		if bits - value + (bound - 1) <= u64(0x7fffffff) { return value }
	}
}

@[export: 'lottery_scheduling']
pub fn lottery_scheduling(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > 51 { return -1 }
		if input[1] < 0 || input[1] > 16 { return -1 }
		process_count := int(input[1])
		if int(input_length) != 2 + 3 * process_count { return -1 }

		mut process_ids := [16]i64{}
		mut burst_times := [16]i64{}
		mut ticket_counts := [16]i64{}
		mut total_tickets := i64(0)
		mut total_burst_time := i64(0)
		for index in 0 .. process_count {
			process_id := input[2 + 3 * index]
			burst_time := input[3 + 3 * index]
			tickets := input[4 + 3 * index]
			if process_id < 0 || process_id > 32767 || burst_time < 1 || burst_time > 1000 || tickets < 1 || tickets > 1000 { return -1 }
			for prior in 0 .. index { if process_ids[prior] == process_id { return -1 } }
			process_ids[index] = process_id
			burst_times[index] = burst_time
			ticket_counts[index] = tickets
			total_tickets += tickets
			total_burst_time += burst_time
		}
		if total_tickets > 16000 || total_burst_time > 16000 { return -1 }

		mut random_state := (u64(input[0]) ^ u64(0x5deece66d)) & ((u64(1) << 48) - 1)
		mut words := [48]i64{}
		mut word_count := 0
		mut current_time := i64(0)
		mut remaining := process_count
		for remaining > 0 {
			mut current_total_tickets := i64(0)
			for index in 0 .. remaining { current_total_tickets += ticket_counts[index] }
			winning_ticket := java_next_int(mut random_state, u64(current_total_tickets)) + u64(1)
			mut cumulative_tickets := u64(0)
			mut selected := remaining
			for index in 0 .. remaining {
				cumulative_tickets += u64(ticket_counts[index])
				if cumulative_tickets >= winning_ticket { selected = index; break }
			}
			if selected == remaining { return -1 }

			waiting_time := current_time
			turnaround_time := waiting_time + burst_times[selected]
			words[word_count] = process_ids[selected]
			words[word_count + 1] = waiting_time
			words[word_count + 2] = turnaround_time
			word_count += 3
			current_time += burst_times[selected]
			for index in selected + 1 .. remaining {
				process_ids[index - 1] = process_ids[index]
				burst_times[index - 1] = burst_times[index]
				ticket_counts[index - 1] = ticket_counts[index]
			}
			remaining--
		}

		output_bytes := word_count * 8
		if output == nil || capacity < usize(output_bytes) || output_bytes > 384 { return -2 }
		for index in 0 .. word_count {
			bits := u64(words[index])
			for byte_index in 0 .. 8 { output[index * 8 + byte_index] = u8((bits >> (byte_index * 8)) & u64(0xff)) }
		}
		return i64(output_bytes)
	}
}
