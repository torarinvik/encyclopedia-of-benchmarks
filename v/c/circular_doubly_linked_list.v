module circular_doubly_linked_list

// Bounded circular doubly linked list using a circular sentinel ring.
@[export: 'circular_doubly_linked_list_benchmark']
pub fn circular_doubly_linked_list_benchmark(values &i64, length usize) i64 {
	if length > 1024 || length % 2 != 0 { return -1 }
	operation_count := length / 2
	mut node_value := [256]i64{init: 0}
	mut next_node := [257]int{init: 0}
	mut prev_node := [257]int{init: 0}
	for i in 0 .. 256 { next_node[i] = i + 1 }
	mut free_head := 0
	mut count := 0
	next_node[256] = 256
	prev_node[256] = 256
	mut checksum := i64(0)
	for operation in 0 .. operation_count {
		opcode := values[2 * operation]
		payload := values[2 * operation + 1]
		mut observed := i64(0)
		mut returns_value := true
		if opcode == 0 || opcode == 1 {
			if payload < -1000000 || payload > 1000000 || count == 256 || free_head == 256 { return -1 }
			node := free_head
			free_head = next_node[node]
			node_value[node] = payload
			mut before := 256
			mut after := 256
			if opcode == 0 { before = prev_node[256] } else { after = next_node[256] }
			next_node[node] = after
			prev_node[node] = before
			next_node[before] = node
			prev_node[after] = node
			count++
			returns_value = false
		} else if opcode == 2 || opcode == 3 {
			if payload != 0 || count == 0 { return -1 }
			mut node := next_node[256]
			if opcode == 3 { node = prev_node[256] }
			observed = node_value[node]
			next_node[prev_node[node]] = next_node[node]
			prev_node[next_node[node]] = prev_node[node]
			next_node[node] = free_head
			free_head = node
			count--
		} else if opcode == 4 || opcode == 5 {
			if payload < -1000000 || payload > 1000000 { return -1 }
			mut node := next_node[256]
			for node != 256 && node_value[node] != payload { node = next_node[node] }
			if node != 256 { observed = 1 }
			if opcode == 4 && node != 256 {
				next_node[prev_node[node]] = next_node[node]
				prev_node[next_node[node]] = prev_node[node]
				next_node[node] = free_head
				free_head = node
				count--
			}
		} else if opcode == 6 {
			if payload != 0 { return -1 }
			observed = i64(count)
		} else if opcode == 7 || opcode == 8 {
			if payload < 0 || payload > 1000000 || count == 0 { return -1 }
			if opcode == 8 && payload >= i64(count) { return -1 }
			mut index := int(payload)
			if opcode == 7 { index %= count }
			mut node := next_node[256]
			if index > count / 2 {
				node = prev_node[256]
				for i := count - 1; i > index; i-- { node = prev_node[node] }
			} else {
				for i := 0; i < index; i++ { node = next_node[node] }
			}
			observed = node_value[node]
			if opcode == 8 {
				next_node[prev_node[node]] = next_node[node]
				prev_node[next_node[node]] = prev_node[node]
				next_node[node] = free_head
				free_head = node
				count--
			}
		} else { return -1 }
		if returns_value { checksum += i64(operation + 1) * (observed + 1000000) }
	}
	mut node := next_node[256]
	mut index := 0
	for node != 256 {
		checksum += (i64(operation_count) + i64(index) + 1) * (node_value[node] + 1000000)
		node = next_node[node]
		index++
	}
	node = prev_node[256]
	index = 0
	for node != 256 {
		checksum += (i64(operation_count) + i64(count) + i64(index) + 1) * (node_value[node] + 1000000)
		node = prev_node[node]
		index++
	}
	return checksum
}
