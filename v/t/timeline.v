fn push_word(mut words &i64, mut count &int, value i64) {
	words[count] = value
	count++
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte_index in 0 .. 8 {
		output[offset + byte_index] = u8((bits >> (byte_index * 8)) & u64(0xff))
	}
}

@[export: 'timeline']
pub fn timeline(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > 131 { return -1 }
		if input[0] < 0 || input[0] > 16 { return -1 }
		initial_count := int(input[0])
		command_count_index := 1 + 2 * initial_count
		if command_count_index >= int(input_length) || input[command_count_index] < 0 || input[command_count_index] > 32 { return -1 }
		command_count := int(input[command_count_index])
		if int(input_length) != 2 + 2 * initial_count + 3 * command_count { return -1 }

		mut event_times := [48]i64{}
		mut event_values := [48]i64{}
		mut operations := [32]i64{}
		mut first_arguments := [32]i64{}
		mut second_arguments := [32]i64{}
		mut event_count := initial_count
		for index in 0 .. initial_count {
			time := input[1 + 2 * index]
			value := input[2 + 2 * index]
			if time < 0 || time > 1000000 || value < -32 || value > 32 { return -1 }
			event_times[index] = time
			event_values[index] = value
		}
		// Stable insertion sort matches the constructor's OrderBy.
		for index in 1 .. initial_count {
			time := event_times[index]
			value := event_values[index]
			mut position := index
			for position > 0 && event_times[position - 1] > time {
				event_times[position] = event_times[position - 1]
				event_values[position] = event_values[position - 1]
				position--
			}
			event_times[position] = time
			event_values[position] = value
		}

		mut offset := command_count_index + 1
		for index in 0 .. command_count {
			opcode := input[offset]
			first := input[offset + 1]
			second := input[offset + 2]
			if opcode < 0 || opcode > 14 { return -1 }
			if opcode <= 2 {
				if first < 0 || first > 1000000 || second < -32 || second > 32 { return -1 }
			} else if opcode == 3 || opcode == 4 || opcode == 5 || opcode == 6 || opcode == 8 {
				if first < 0 || first > 1000000 || second != 0 { return -1 }
			} else if opcode == 7 || opcode == 9 {
				if first < -32 || first > 32 || second != 0 { return -1 }
			} else if first != 0 || second != 0 { return -1 }
			operations[index] = opcode
			first_arguments[index] = first
			second_arguments[index] = second
			offset += 3
		}

		mut words := [691]i64{}
		mut word_count := 0
		for command in 0 .. command_count {
			opcode := operations[command]
			first := first_arguments[command]
			second := second_arguments[command]
			count_index := word_count + 1
			push_word(mut words[0], mut word_count, opcode)
			push_word(mut words[0], mut word_count, 0)

			if opcode == 0 {
				event_times[event_count] = first
				event_values[event_count] = second
				event_count++
			} else if opcode == 1 {
				mut found := false
				for index in 0 .. event_count {
					if event_times[index] == first && event_values[index] == second { found = true }
				}
				push_word(mut words[0], mut word_count, if found { i64(1) } else { i64(0) })
			} else if opcode == 2 {
				mut found := -1
				for index in 0 .. event_count {
					if event_times[index] == first && event_values[index] == second { found = index; break }
				}
				if found >= 0 {
					for index in found + 1 .. event_count {
						event_times[index - 1] = event_times[index]
						event_values[index - 1] = event_values[index]
					}
					event_count--
					push_word(mut words[0], mut word_count, 1)
				} else { push_word(mut words[0], mut word_count, 0) }
			} else if opcode == 3 {
				for index in 0 .. event_count {
					if event_times[index] == first { push_word(mut words[0], mut word_count, event_values[index]) }
				}
			} else if opcode == 4 || opcode == 5 || opcode == 10 || opcode == 12 {
				mut unique := [48]i64{}
				mut unique_count := 0
				for index in 0 .. event_count {
					mut seen := false
					for prior in 0 .. index { if event_times[prior] == event_times[index] { seen = true } }
					include := opcode == 10 || opcode == 12 || (opcode == 4 && event_times[index] < first) || (opcode == 5 && event_times[index] > first)
					if !seen && include { unique[unique_count] = event_times[index]; unique_count++ }
				}
				if opcode == 4 || opcode == 5 {
					for index in 1 .. unique_count {
						value := unique[index]
						mut position := index
						for position > 0 && unique[position - 1] > value { unique[position] = unique[position - 1]; position-- }
						unique[position] = value
					}
				}
				if opcode == 12 { push_word(mut words[0], mut word_count, i64(unique_count)) }
				else { for index in 0 .. unique_count { push_word(mut words[0], mut word_count, unique[index]) } }
			} else if opcode == 6 || opcode == 7 {
				by_time := opcode == 6
				mut existed := false
				mut write := 0
				for index in 0 .. event_count {
					matches := if by_time { event_times[index] == first } else { event_values[index] == first }
					if matches { existed = true }
					else { event_times[write] = event_times[index]; event_values[write] = event_values[index]; write++ }
				}
				event_count = write
				push_word(mut words[0], mut word_count, if existed { i64(1) } else { i64(0) })
			} else if opcode == 8 || opcode == 9 {
				mut found := false
				for index in 0 .. event_count {
					if (opcode == 8 && event_times[index] == first) || (opcode == 9 && event_values[index] == first) { found = true }
				}
				push_word(mut words[0], mut word_count, if found { i64(1) } else { i64(0) })
			} else if opcode == 11 {
				for index in 0 .. event_count { push_word(mut words[0], mut word_count, event_values[index]) }
			} else if opcode == 13 { push_word(mut words[0], mut word_count, i64(event_count)) }
			else { event_count = 0 }

			words[count_index] = i64(word_count - count_index - 1)
		}

		push_word(mut words[0], mut word_count, -1)
		push_word(mut words[0], mut word_count, i64(event_count))
		for index in 0 .. event_count {
			push_word(mut words[0], mut word_count, event_times[index])
			push_word(mut words[0], mut word_count, event_values[index])
		}
		output_bytes := word_count * 8
		if output == nil || capacity < usize(output_bytes) || output_bytes > 5528 { return -2 }
		for index in 0 .. word_count { put_i64_le(mut output[0], index * 8, words[index]) }
		return i64(output_bytes)
	}
}
