package timeline

import "core:c"

MAX_INITIAL_EVENTS :: 16
MAX_COMMANDS :: 32
MAX_EVENTS :: 48
MAX_PARSEABLE_INPUT_LENGTH :: 131
MAX_OUTPUT_WORDS :: 691
MAX_OUTPUT_BYTES :: 5528

push_word :: proc "contextless" (words: [^]i64, count: ^int, value: i64) {
	words[count^] = value
	count^ += 1
}

@(export)
timeline :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_INITIAL_EVENTS do return -1
	initial_count := int(input[0])
	command_count_index := 1 + 2*initial_count
	if command_count_index >= int(input_length) || input[command_count_index] < 0 ||
		input[command_count_index] > MAX_COMMANDS do return -1
	command_count := int(input[command_count_index])
	if int(input_length) != 2 + 2*initial_count + 3*command_count do return -1

	event_times: [MAX_EVENTS]i64
	event_values: [MAX_EVENTS]i64
	operations: [MAX_COMMANDS]i64
	first_arguments: [MAX_COMMANDS]i64
	second_arguments: [MAX_COMMANDS]i64
	event_count := initial_count
	for index in 0..<initial_count {
		time := input[1+2*index]
		value := input[2+2*index]
		if time < 0 || time > 1_000_000 || value < -32 || value > 32 do return -1
		event_times[index] = time
		event_values[index] = value
	}
	// Stable insertion sort matches the constructor's OrderBy.
	for index in 1..<initial_count {
		time := event_times[index]
		value := event_values[index]
		position := index
		for position > 0 && event_times[position-1] > time {
			event_times[position] = event_times[position-1]
			event_values[position] = event_values[position-1]
			position -= 1
		}
		event_times[position] = time
		event_values[position] = value
	}

	offset := command_count_index + 1
	for index in 0..<command_count {
		opcode := input[offset]
		first := input[offset+1]
		second := input[offset+2]
		if opcode < 0 || opcode > 14 do return -1
		if opcode <= 2 {
			if first < 0 || first > 1_000_000 || second < -32 || second > 32 do return -1
		} else if opcode == 3 || opcode == 4 || opcode == 5 || opcode == 6 || opcode == 8 {
			if first < 0 || first > 1_000_000 || second != 0 do return -1
		} else if opcode == 7 || opcode == 9 {
			if first < -32 || first > 32 || second != 0 do return -1
		} else if first != 0 || second != 0 do return -1
		operations[index] = opcode
		first_arguments[index] = first
		second_arguments[index] = second
		offset += 3
	}

	words: [MAX_OUTPUT_WORDS]i64
	word_count := 0
	for command in 0..<command_count {
		opcode := operations[command]
		first := first_arguments[command]
		second := second_arguments[command]
		count_index := word_count + 1
		push_word(&words[0], &word_count, opcode)
		push_word(&words[0], &word_count, 0)

		if opcode == 0 {
			event_times[event_count] = first
			event_values[event_count] = second
			event_count += 1
		} else if opcode == 1 {
			found := false
			for index in 0..<event_count { if event_times[index] == first && event_values[index] == second { found = true } }
			result := i64(0); if found { result = 1 }
			push_word(&words[0], &word_count, result)
		} else if opcode == 2 {
			found := event_count
			for index in 0..<event_count {
				if event_times[index] == first && event_values[index] == second { found = index; break }
			}
			if found < event_count {
				for index in found+1..<event_count { event_times[index-1] = event_times[index]; event_values[index-1] = event_values[index] }
				event_count -= 1
				push_word(&words[0], &word_count, 1)
			} else { push_word(&words[0], &word_count, 0) }
		} else if opcode == 3 {
			for index in 0..<event_count { if event_times[index] == first { push_word(&words[0], &word_count, event_values[index]) } }
		} else if opcode == 4 || opcode == 5 || opcode == 10 || opcode == 12 {
			unique: [MAX_EVENTS]i64
			unique_count := 0
			for index in 0..<event_count {
				seen := false
				for prior in 0..<index { if event_times[prior] == event_times[index] { seen = true } }
				include := opcode == 10 || opcode == 12 || (opcode == 4 && event_times[index] < first) || (opcode == 5 && event_times[index] > first)
				if !seen && include { unique[unique_count] = event_times[index]; unique_count += 1 }
			}
			if opcode == 4 || opcode == 5 {
				for index in 1..<unique_count {
					value := unique[index]
					position := index
					for position > 0 && unique[position-1] > value { unique[position] = unique[position-1]; position -= 1 }
					unique[position] = value
				}
			}
			if opcode == 12 { push_word(&words[0], &word_count, i64(unique_count)) }
			else { for index in 0..<unique_count { push_word(&words[0], &word_count, unique[index]) } }
		} else if opcode == 6 || opcode == 7 {
			by_time := opcode == 6
			existed := false
			write := 0
			for index in 0..<event_count {
				matches := (by_time && event_times[index] == first) || (!by_time && event_values[index] == first)
				if matches { existed = true }
				else { event_times[write] = event_times[index]; event_values[write] = event_values[index]; write += 1 }
			}
			event_count = write
			result := i64(0); if existed { result = 1 }
			push_word(&words[0], &word_count, result)
		} else if opcode == 8 || opcode == 9 {
			found := false
			for index in 0..<event_count {
				if (opcode == 8 && event_times[index] == first) || (opcode == 9 && event_values[index] == first) { found = true }
			}
			result := i64(0); if found { result = 1 }
			push_word(&words[0], &word_count, result)
		} else if opcode == 11 {
			for index in 0..<event_count { push_word(&words[0], &word_count, event_values[index]) }
		} else if opcode == 13 { push_word(&words[0], &word_count, i64(event_count)) }
		else { event_count = 0 }

		words[count_index] = i64(word_count-count_index-1)
	}

	push_word(&words[0], &word_count, -1)
	push_word(&words[0], &word_count, i64(event_count))
	for index in 0..<event_count { push_word(&words[0], &word_count, event_times[index]); push_word(&words[0], &word_count, event_values[index]) }
	output_bytes := word_count * 8
	if output == nil || capacity < c.size_t(output_bytes) || output_bytes > MAX_OUTPUT_BYTES do return -2
	for index in 0..<word_count {
		bits := u64(words[index])
		for byte in 0..<8 { output[index*8+byte] = u8((bits >> (byte*8)) & 0xff) }
	}
	return i64(output_bytes)
}
