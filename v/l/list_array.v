module list_array

@[export: 'list_array']
pub fn list_array(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if input == nil || length < 2 || length > 130 { return -1 }
	capacity_value := unsafe { input[0] }
	operation_count_value := unsafe { input[1] }
	if capacity_value < 1 || capacity_value > 16 || operation_count_value < 1 || operation_count_value > 64 { return -1 }
	capacity := int(capacity_value)
	operations := int(operation_count_value)
	if length != usize(2 + 2 * operations) { return -1 }

	mut opcodes := [64]i64{}
	mut arguments := [64]i64{}
	mut sorted := false
	for i in 0 .. operations {
		opcode := unsafe { input[2 + 2 * i] }
		argument := unsafe { input[3 + 2 * i] }
		if opcode == 0 {
			if sorted || argument < 0 { return -1 }
		} else if opcode == 1 {
			if sorted || argument != 0 { return -1 }
			sorted = true
		} else if opcode == 2 || opcode == 3 {
			if !sorted || argument < 0 { return -1 }
		} else { return -1 }
		opcodes[i] = opcode
		arguments[i] = argument
	}
	if !sorted { return -1 }

	mut items := [16]u64{}
	mut results := [64]i64{}
	mut output_words := [65]i64{}
	mut count := 0
	mut result_count := 0
	for i in 0 .. operations {
		opcode := opcodes[i]
		argument := arguments[i]
		if opcode == 0 {
			if count == capacity { return -1 }
			items[count] = u64(argument)
			count++
		} else if opcode == 1 {
			for a in 0 .. count {
				mut minimum := a
				for b in a + 1 .. count { if items[b] < items[minimum] { minimum = b } }
				value := items[minimum]
				items[minimum] = items[a]
				items[a] = value
			}
		} else {
			if count == 0 || u64(argument) < items[0] { return -1 }
			if opcode == 3 && count >= capacity { return -1 }
			mut first := 0
			mut last := count - 1
			mut position := i64(-1)
			for first <= last {
				middle := (first + last) / 2
				value := items[middle]
				if value == u64(argument) {
					position = i64(middle)
					break
				} else if u64(argument) < value {
					last = middle - 1
				} else {
					first = middle + 1
				}
			}
			results[result_count] = position
			result_count++
			if opcode == 3 && position >= 0 {
				mut j := int(position)
				for j < count { items[j] = items[j + 1]; j++ }
				count--
			}
		}
	}

	mut word_count := 0
	output_words[word_count] = i64(result_count)
	word_count++
	for i in 0 .. result_count { output_words[word_count] = results[i]; word_count++ }
	output_words[word_count] = i64(count)
	word_count++
	for i in 0 .. count { output_words[word_count] = i64(items[i]); word_count++ }
	required := word_count * 8
	if output == nil || output_capacity < usize(required) { return -2 }
	for i in 0 .. word_count {
		bits := u64(output_words[i])
		for byte in 0 .. 8 {
			unsafe { output[i * 8 + byte] = u8((bits >> (8 * byte)) & 255) }
		}
	}
	return i64(required)
}
