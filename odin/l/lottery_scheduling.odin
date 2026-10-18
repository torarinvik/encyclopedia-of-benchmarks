package lottery_scheduling

import "core:c"

MAX_PROCESSES :: 16
MAX_PARSEABLE_INPUT_LENGTH :: 51
MAX_OUTPUT_BYTES :: 384
JAVA_MULTIPLIER :: u64(0x5DEECE66D)
JAVA_ADDEND :: u64(0xB)
JAVA_MASK :: (u64(1) << 48) - 1
INT32_MAX_VALUE :: u64(0x7fffffff)

next_java_state :: proc "contextless" (state: u64) -> u64 {
	low := state & 0xffffff
	high := state >> 24
	low_product := low * JAVA_MULTIPLIER
	high_product := (high * JAVA_MULTIPLIER) & 0xffffff
	return (low_product + (high_product << 24) + JAVA_ADDEND) & JAVA_MASK
}

java_next_int :: proc "contextless" (state: ^u64, bound: u64) -> u64 {
	if (bound & (bound - 1)) == 0 {
		state^ = next_java_state(state^)
		return (bound * (state^ >> 17)) >> 31
	}
	for {
		state^ = next_java_state(state^)
		bits := state^ >> 17
		value := bits % bound
		if bits-value+(bound-1) <= INT32_MAX_VALUE do return value
	}
}

@(export)
lottery_scheduling :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input[1] < 0 || input[1] > MAX_PROCESSES do return -1
	process_count := int(input[1])
	if int(input_length) != 2 + 3*process_count do return -1

	process_ids: [MAX_PROCESSES]i64
	burst_times: [MAX_PROCESSES]i64
	ticket_counts: [MAX_PROCESSES]i64
	total_tickets := i64(0)
	total_burst_time := i64(0)
	for index in 0..<process_count {
		process_id := input[2+3*index]
		burst_time := input[3+3*index]
		tickets := input[4+3*index]
		if process_id < 0 || process_id > 32767 || burst_time < 1 || burst_time > 1000 || tickets < 1 || tickets > 1000 do return -1
		for prior in 0..<index { if process_ids[prior] == process_id do return -1 }
		process_ids[index] = process_id
		burst_times[index] = burst_time
		ticket_counts[index] = tickets
		total_tickets += tickets
		total_burst_time += burst_time
	}
	if total_tickets > 16000 || total_burst_time > 16000 do return -1

	random_state := (u64(input[0]) ^ JAVA_MULTIPLIER) & JAVA_MASK
	words: [3*MAX_PROCESSES]i64
	word_count := 0
	current_time := i64(0)
	remaining := process_count
	for remaining > 0 {
		current_total_tickets := i64(0)
		for index in 0..<remaining { current_total_tickets += ticket_counts[index] }
		winning_ticket := java_next_int(&random_state, u64(current_total_tickets)) + 1
		cumulative_tickets := u64(0)
		selected := remaining
		for index in 0..<remaining {
			cumulative_tickets += u64(ticket_counts[index])
			if cumulative_tickets >= winning_ticket { selected = index; break }
		}
		if selected == remaining do return -1

		waiting_time := current_time
		turnaround_time := waiting_time + burst_times[selected]
		words[word_count] = process_ids[selected]
		words[word_count+1] = waiting_time
		words[word_count+2] = turnaround_time
		word_count += 3
		current_time += burst_times[selected]
		for index in selected+1..<remaining {
			process_ids[index-1] = process_ids[index]
			burst_times[index-1] = burst_times[index]
			ticket_counts[index-1] = ticket_counts[index]
		}
		remaining -= 1
	}

	output_bytes := word_count * 8
	if output == nil || capacity < c.size_t(output_bytes) || output_bytes > MAX_OUTPUT_BYTES do return -2
	for index in 0..<word_count {
		bits := u64(words[index])
		for byte in 0..<8 { output[index*8+byte] = u8((bits >> (byte*8)) & 0xff) }
	}
	return i64(output_bytes)
}
