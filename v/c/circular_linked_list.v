module circular_linked_list

const capacity = 256
const sentinel = 256
const value_offset = i64(1_000_000)

// Bounded singly circular linked list operation trace.
@[export: 'circular_linked_list_benchmark']
pub fn circular_linked_list_benchmark(values &i64, length usize) i64 {
	if length > 1024 || length % 2 != 0 { return -1 }
	operation_count := int(length / 2)
	mut node_value := [capacity]i64{init: 0}
	mut next_node := [capacity + 1]int{init: 0}
	for index in 0 .. capacity { next_node[index] = index + 1 }
	next_node[sentinel] = sentinel
	mut free_head := 0
	mut tail := sentinel
	mut count := 0
	mut checksum := i64(0)
	for operation in 0 .. operation_count {
		opcode := values[2 * operation]
		payload := values[2 * operation + 1]
		mut observed := i64(0)
		mut returns_value := true
		if opcode == 0 || opcode == 1 {
			if payload < -value_offset || payload > value_offset || count == capacity || free_head == sentinel { return -1 }
			node := free_head
			free_head = next_node[node]
			node_value[node] = payload
			if opcode == 0 {
				next_node[node] = sentinel
				next_node[tail] = node
				tail = node
			} else {
				next_node[node] = next_node[sentinel]
				next_node[sentinel] = node
				if count == 0 { tail = node }
			}
			count++
			returns_value = false
		} else if opcode == 2 || opcode == 3 {
			if payload != 0 || count == 0 { return -1 }
			mut previous := sentinel
			if opcode == 3 { for next_node[previous] != tail { previous = next_node[previous] } }
			node := next_node[previous]
			observed = node_value[node]
			next_node[previous] = next_node[node]
			if node == tail { tail = previous }
			next_node[node] = free_head
			free_head = node
			count--
		} else if opcode == 4 || opcode == 5 {
			if payload < -value_offset || payload > value_offset { return -1 }
			mut previous := sentinel
			for next_node[previous] != sentinel && node_value[next_node[previous]] != payload { previous = next_node[previous] }
			node := next_node[previous]
			if node != sentinel { observed = 1 }
			if opcode == 4 && node != sentinel {
				next_node[previous] = next_node[node]
				if node == tail { tail = previous }
				next_node[node] = free_head
				free_head = node
				count--
			}
		} else if opcode == 6 {
			if payload != 0 { return -1 }
			observed = i64(count)
		} else if opcode == 7 || opcode == 8 {
			if payload < 0 || payload > 1_000_000 || count == 0 || payload >= i64(count) { return -1 }
			mut previous := sentinel
			for _ in 0 .. int(payload) { previous = next_node[previous] }
			node := next_node[previous]
			observed = node_value[node]
			if opcode == 8 {
				next_node[previous] = next_node[node]
				if node == tail { tail = previous }
				next_node[node] = free_head
				free_head = node
				count--
			}
		} else { return -1 }
		if returns_value { checksum += i64(operation + 1) * (observed + value_offset) }
	}
	mut node := next_node[sentinel]
	mut index := 0
	for node != sentinel {
		checksum += (i64(operation_count + index) + 1) * (node_value[node] + value_offset)
		node = next_node[node]
		index++
	}
	return checksum
}
