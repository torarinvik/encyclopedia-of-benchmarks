struct SinglyList {
	mut:
	values [96]i64
	next   [96]int
	used   int
	head   int = -1
	tail   int = -1
	length int
}

fn (mut list SinglyList) allocate(value i64) int {
	node := list.used
	list.used++
	list.values[node] = value
	list.next[node] = -1
	return node
}

fn (mut list SinglyList) add_head(value i64) {
	node := list.allocate(value)
	list.next[node] = list.head
	if list.head < 0 { list.tail = node }
	list.head = node
	list.length++
}

fn (mut list SinglyList) add_tail(value i64) {
	node := list.allocate(value)
	if list.tail < 0 { list.head = node } else { list.next[list.tail] = node }
	list.tail = node
	list.length++
}

fn (mut list SinglyList) delete_head() (i64, bool) {
	if list.head < 0 { return 0, false }
	node := list.head
	value := list.values[node]
	list.head = list.next[node]
	list.length--
	if list.length == 0 { list.tail = -1 }
	return value, true
}

fn (mut list SinglyList) delete_tail() (i64, bool) {
	if list.tail < 0 { return 0, false }
	value := list.values[list.tail]
	if list.length == 1 {
		list.head = -1
		list.tail = -1
	} else {
		mut previous := list.head
		for list.next[previous] != list.tail { previous = list.next[previous] }
		list.next[previous] = -1
		list.tail = previous
	}
	list.length--
	return value, true
}

fn (mut list SinglyList) delete_position(position int) (i64, bool) {
	if list.length == 0 { return 0, false }
	if position == 1 { return list.delete_head() }
	if position >= list.length { return list.delete_tail() }
	mut previous := list.head
	for step in 1 .. position-1 { previous = list.next[previous] }
	node := list.next[previous]
	value := list.values[node]
	list.next[previous] = list.next[node]
	list.length--
	return value, true
}

fn (mut list SinglyList) reverse() {
	mut previous := -1
	mut current := list.head
	list.tail = list.head
	for current >= 0 {
		following := list.next[current]
		list.next[current] = previous
		previous = current
		current = following
	}
	list.head = previous
}

fn (mut list SinglyList) reverse_range(left int, right int) {
	mut before := -1
	mut start := list.head
	for _ in 1 .. left { before = start; start = list.next[start] }
	mut previous := -1
	mut current := start
	for _ in left .. right+1 {
		following := list.next[current]
		list.next[current] = previous
		previous = current
		current = following
	}
	list.next[start] = current
	if before < 0 { list.head = previous } else { list.next[before] = previous }
	if right == list.length { list.tail = start }
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'singlylinkedlist']
pub fn singlylinkedlist(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 227 { return -1 }
		initial_count_value := input[0]
		operation_count_value := input[1]
		if initial_count_value < 0 || initial_count_value > 32 || operation_count_value < 0 || operation_count_value > 64 { return -1 }
		initial_count := int(initial_count_value)
		operation_count := int(operation_count_value)
		if length < usize(2+initial_count) { return -1 }
		mut list := SinglyList{}
		for i in 0 .. initial_count {
			value := input[2+i]
			if value < -1_000_000 || value > 1_000_000 { return -1 }
			list.add_tail(value)
		}
		mut results := [128]i64{}
		mut cursor := 2 + initial_count
		for operation in 0 .. operation_count {
			if cursor >= int(length) { return -1 }
			opcode := input[cursor]
			cursor++
			mut arg1 := i64(0)
			mut arg2 := i64(0)
			if opcode == 0 || opcode == 1 || opcode == 4 {
				if cursor >= int(length) { return -1 }
				arg1 = input[cursor]
				cursor++
			} else if opcode == 6 {
				if int(length)-cursor < 2 { return -1 }
				arg1 = input[cursor]
				arg2 = input[cursor+1]
				cursor += 2
			} else if opcode != 2 && opcode != 3 && opcode != 5 { return -1 }
			mut success := i64(1)
			mut value := i64(0)
			if opcode == 0 || opcode == 1 {
				if arg1 < -1_000_000 || arg1 > 1_000_000 { return -1 }
				if opcode == 0 { list.add_head(arg1) } else { list.add_tail(arg1) }
			} else if opcode == 2 {
				deleted, found := list.delete_head()
				value = deleted
				if !found { success = 0 }
			} else if opcode == 3 {
				deleted, found := list.delete_tail()
				value = deleted
				if !found { success = 0 }
			} else if opcode == 4 {
				if list.length == 0 {
					if arg1 != 1 { return -1 }
					success = 0
				} else {
					if arg1 < 1 || arg1 > i64(list.length+1) { return -1 }
					value, _ = list.delete_position(int(arg1))
				}
			} else if opcode == 5 {
				list.reverse()
			} else {
				if arg1 < 1 || arg2 < arg1 || arg2 > i64(list.length) { return -1 }
				list.reverse_range(int(arg1), int(arg2))
			}
			results[operation*2] = success
			results[operation*2+1] = value
		}
		if cursor != int(length) { return -1 }
		output_values := 1 + list.length + 1 + operation_count*2
		output_bytes := output_values * 8
		if output_bytes > 1808 { return -1 }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		put_i64_le(mut output, 0, i64(list.length))
		mut offset := 8
		mut node := list.head
		for node >= 0 { put_i64_le(mut output, offset, list.values[node]); offset += 8; node = list.next[node] }
		put_i64_le(mut output, offset, i64(operation_count))
		offset += 8
		for i in 0 .. operation_count*2 { put_i64_le(mut output, offset, results[i]); offset += 8 }
		return i64(output_bytes)
	}
}
