fn put_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'sorted_linked_list']
pub fn sorted_linked_list(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 20 { return -1 }
		if input[0] < 0 || input[0] > 16 { return -1 }
		count := int(input[0])
		if input_length != usize(count + 3) { return -1 }

		mut node_values := [17]i64{}
		mut next := [17]int{}
		for index in 0 .. count {
			value := input[index + 1]
			if value < -2147483648 || value > 2147483647 || (index > 0 && input[index] >= value) { return -1 }
			node_values[index] = value
			next[index] = if index + 1 < count { index + 1 } else { -1 }
		}
		operation_value, key := input[count + 1], input[count + 2]
		if operation_value < 0 || operation_value > 2 || key < -2147483648 || key > 2147483647 { return -1 }
		operation := int(operation_value)
		mut head := if count == 0 { -1 } else { 0 }
		mut tail := if count == 0 { -1 } else { count - 1 }

		if operation == 0 {
			mut current := head
			for current >= 0 {
				if node_values[current] == key { return -1 }
				current = next[current]
			}
		}

		mut staged := [18]i64{}
		mut word_count := 0
		if operation == 0 {
			new_node := count
			node_values[new_node] = key
			next[new_node] = -1
			if head < 0 { head, tail = new_node, new_node }
			else if key < node_values[head] { next[new_node] = head; head = new_node }
			else if key > node_values[tail] { next[tail] = new_node; tail = new_node }
			else {
				mut previous := head
				for next[previous] >= 0 && node_values[next[previous]] < key { previous = next[previous] }
				next[new_node] = next[previous]
				next[previous] = new_node
				if next[new_node] < 0 { tail = new_node }
			}
			staged[word_count] = i64(count + 1)
			word_count++
			mut node := head
			for node >= 0 {
				staged[word_count] = node_values[node]
				word_count++
				node = next[node]
			}
		} else if operation == 1 {
			mut found := i64(0)
			mut node := head
			for node >= 0 {
				if node_values[node] == key { found = 1; break }
				node = next[node]
			}
			staged[word_count] = found
			word_count++
		} else {
			mut deleted := i64(0)
			if head >= 0 && node_values[head] == key {
				head = next[head]
				if head < 0 { tail = -1 }
				deleted = 1
			} else {
				mut previous := head
				for previous >= 0 && next[previous] >= 0 {
					candidate := next[previous]
					if node_values[candidate] == key {
						next[previous] = next[candidate]
						if tail == candidate { tail = previous }
						deleted = 1
						break
					}
					previous = candidate
				}
			}
			staged[word_count] = deleted
			word_count++
			mut remaining := 0
			mut node := head
			for node >= 0 { remaining++; node = next[node] }
			staged[word_count] = i64(remaining)
			word_count++
			node = head
			for node >= 0 {
				staged[word_count] = node_values[node]
				word_count++
				node = next[node]
			}
		}

		output_bytes := word_count * 8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. word_count { put_i64_le(mut output, index * 8, staged[index]) }
		return i64(output_bytes)
	}
}
