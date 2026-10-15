module ascending_priority_queue

// Bounded linked-node pool for an ascending priority queue.
@[export: 'ascending_priority_queue']
pub fn ascending_priority_queue(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	operation_count := unsafe { input[0] }
	if operation_count < 0 || operation_count > 512 || length != usize(1 + 2 * operation_count) { return -1 }

	mut node_values := [64]i64{init: 0}
	mut node_next := [64]int{init: 0}
	for index in 0 .. 63 { node_next[index] = index + 1 }
	node_next[63] = -1
	mut free_head := 0
	mut front := -1
	mut rear := -1
	mut checksum := i64(0)

	for operation in 0 .. int(operation_count) {
		opcode := unsafe { input[1 + 2 * operation] }
		payload := unsafe { input[2 + 2 * operation] }
		if opcode == 0 {
			if payload < -1_000_000 || payload > 1_000_000 || free_head < 0 { return -1 }
			node := free_head
			free_head = node_next[node]
			node_values[node] = payload
			node_next[node] = -1
			if front < 0 { front = node; rear = node }
			else { node_next[rear] = node; rear = node }
		} else if opcode == 1 {
			if payload != 0 || front < 0 { return -1 }
			mut previous := -1
			mut current := front
			mut minimum := front
			mut minimum_previous := -1
			for current >= 0 {
				if node_values[current] < node_values[minimum] {
					minimum = current
					minimum_previous = previous
				}
				previous = current
				current = node_next[current]
			}
			checksum += i64(operation + 1) * (node_values[minimum] + 1_000_001)
			if minimum_previous < 0 { front = node_next[minimum] }
			else { node_next[minimum_previous] = node_next[minimum] }
			if rear == minimum { rear = minimum_previous }
			node_next[minimum] = free_head
			free_head = minimum
		} else { return -1 }
	}

	mut position := i64(1)
	mut current := front
	for current >= 0 {
		checksum += position * (node_values[current] + 1_000_001)
		current = node_next[current]
		position++
	}
	return checksum
}
