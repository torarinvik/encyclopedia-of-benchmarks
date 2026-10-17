module list_based_queue

@[export: 'list_based_queue']
pub fn list_based_queue(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 66 { return -1 }
	if unsafe { input[0] < 0 || input[0] > 32 } { return -1 }
	op_count := int(unsafe { input[0] })
	mut node_values := []i32{len: 32}
	mut next_node := []i32{len: 32}
	mut words := []i64{len: 64}
	mut allocated := 0
	mut word_count := 0
	mut pos := 1
	mut size := 0
	mut head := -1
	mut tail := -1
	for _ in 0 .. op_count {
		if pos >= int(length) { return -1 }
		opcode := unsafe { input[pos] }
		pos++
		if opcode == 0 {
			if pos >= int(length) { return -1 }
			value := unsafe { input[pos] }
			pos++
			if value < -2147483648 || value > 2147483647 || allocated >= 32 { return -1 }
			node_values[allocated] = i32(value)
			next_node[allocated] = -1
			if tail < 0 { head = allocated }
			else { next_node[tail] = allocated }
			tail = allocated
			allocated++
			size++
			words[word_count] = 0
			words[word_count + 1] = 1
			word_count += 2
		} else if opcode == 1 {
			if head < 0 { return -1 }
			node := head
			head = next_node[node]
			if head < 0 { tail = -1 }
			size--
			words[word_count] = 1
			words[word_count + 1] = i64(node_values[node])
			word_count += 2
		} else if opcode == 2 {
			if head < 0 { return -1 }
			words[word_count] = 2
			words[word_count + 1] = i64(node_values[head])
			word_count += 2
		} else if opcode == 3 {
			head = -1
			tail = -1
			size = 0
			words[word_count] = 3
			words[word_count + 1] = 1
			word_count += 2
		} else if opcode == 4 {
			words[word_count] = 4
			words[word_count + 1] = if size == 0 { 1 } else { 0 }
			word_count += 2
		} else if opcode == 5 {
			words[word_count] = 5
			words[word_count + 1] = 0
			word_count += 2
		} else { return -1 }
	}
	if pos != int(length) || int(length) > 1 + 2 * op_count || word_count > 64 { return -1 }
	bytes := word_count * 8
	if unsafe { output == nil } || output_capacity < bytes { return -2 }
	for i in 0 .. word_count {
		bits := u64(words[i])
		for b in 0 .. 8 {
			unsafe { output[8 * i + b] = u8((bits >> (8 * b)) & 255) }
		}
	}
	return i64(bytes)
}
