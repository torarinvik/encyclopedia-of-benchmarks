package ascending_priority_queue

import "core:c"

MAX_OPERATIONS :: 512
MAX_CAPACITY :: 64

@(export)
ascending_priority_queue :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	operation_count := input[0]
	if operation_count < 0 || operation_count > MAX_OPERATIONS || length != c.size_t(1 + 2 * operation_count) do return -1

	node_values: [MAX_CAPACITY]i64
	node_next: [MAX_CAPACITY]int
	for index := 0; index < MAX_CAPACITY - 1; index += 1 { node_next[index] = index + 1 }
	node_next[MAX_CAPACITY - 1] = -1
	free_head, front, rear := 0, -1, -1
	checksum: i64 = 0

	for operation := 0; operation < int(operation_count); operation += 1 {
		opcode := input[1 + 2 * operation]
		payload := input[2 + 2 * operation]
		if opcode == 0 {
			if payload < -1_000_000 || payload > 1_000_000 || free_head < 0 do return -1
			node := free_head
			free_head = node_next[node]
			node_values[node] = payload
			node_next[node] = -1
			if front < 0 { front = node; rear = node }
			else { node_next[rear] = node; rear = node }
		} else if opcode == 1 {
			if payload != 0 || front < 0 do return -1
			previous, current := -1, front
			minimum, minimum_previous := front, -1
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
		} else {
			return -1
		}
	}

	position: i64 = 1
	for node := front; node >= 0; node = node_next[node] {
		checksum += position * (node_values[node] + 1_000_001)
		position += 1
	}
	return checksum
}
