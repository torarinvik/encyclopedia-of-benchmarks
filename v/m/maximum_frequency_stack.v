module maximum_frequency_stack

fn store_i64(output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'maximum_frequency_stack']
pub fn maximum_frequency_stack(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 130 { return -1 }
		count := input[0]
		if count < 0 || count > 64 || length != usize(1 + 2 * count) { return -1 }
		mut frequency := [17]int{}
		mut bucket_top := [65]int{}
		for i in 0 .. 65 { bucket_top[i] = -1 }
		mut node_value := [64]int{}
		mut node_next := [64]int{}
		mut popped := [64]i64{}
		mut nodes := 0
		mut pop_count := 0
		mut position := 1
		mut maximum_frequency := 0
		for _ in 0 .. int(count) {
			opcode := input[position]
			argument := input[position + 1]
			position += 2
			if opcode == 0 {
				if argument < -8 || argument > 8 { return -1 }
				index := int(argument) + 8
				frequency[index]++
				level := frequency[index]
				node_value[nodes] = int(argument)
				node_next[nodes] = bucket_top[level]
				bucket_top[level] = nodes
				nodes++
				if level > maximum_frequency { maximum_frequency = level }
			} else if opcode == 1 && argument == 0 {
				if maximum_frequency == 0 || bucket_top[maximum_frequency] < 0 { return -1 }
				node := bucket_top[maximum_frequency]
				bucket_top[maximum_frequency] = node_next[node]
				value := node_value[node]
				popped[pop_count] = i64(value)
				pop_count++
				frequency[value + 8]--
				if bucket_top[maximum_frequency] < 0 { maximum_frequency-- }
			} else { return -1 }
		}
		needed := pop_count * 8
		if needed > 0 && (output == nil || capacity < usize(needed)) { return -2 }
		for i in 0 .. pop_count { store_i64(output, i * 8, popped[i]) }
		return i64(needed)
	}
}
