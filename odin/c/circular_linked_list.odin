package circular_linked_list

import "core:c"

CAPACITY :: 256
SENTINEL :: CAPACITY
VALUE_OFFSET :: i64(1_000_000)

@(export)
circular_linked_list_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 1024 || length % 2 != 0 do return -1
	operation_count := int(length / 2)
	node_value: [CAPACITY]i64
	next_node: [CAPACITY + 1]int
	for index := 0; index < CAPACITY; index += 1 { next_node[index] = index + 1 }
	next_node[SENTINEL] = SENTINEL
	free_head := 0
	tail := SENTINEL
	count := 0
	checksum := i64(0)
	for operation := 0; operation < operation_count; operation += 1 {
		opcode, payload := values[2 * operation], values[2 * operation + 1]
		observed := i64(0)
		returns_value := true
		if opcode == 0 || opcode == 1 {
			if payload < -VALUE_OFFSET || payload > VALUE_OFFSET || count == CAPACITY || free_head == SENTINEL do return -1
			node := free_head
			free_head = next_node[node]
			node_value[node] = payload
			if opcode == 0 {
				next_node[node] = SENTINEL
				next_node[tail] = node
				tail = node
			} else {
				next_node[node] = next_node[SENTINEL]
				next_node[SENTINEL] = node
				if count == 0 do tail = node
			}
			count += 1
			returns_value = false
		} else if opcode == 2 || opcode == 3 {
			if payload != 0 || count == 0 do return -1
			previous := SENTINEL
			if opcode == 3 { for next_node[previous] != tail { previous = next_node[previous] } }
			node := next_node[previous]
			observed = node_value[node]
			next_node[previous] = next_node[node]
			if node == tail do tail = previous
			next_node[node] = free_head
			free_head = node
			count -= 1
		} else if opcode == 4 || opcode == 5 {
			if payload < -VALUE_OFFSET || payload > VALUE_OFFSET do return -1
			previous := SENTINEL
			for next_node[previous] != SENTINEL && node_value[next_node[previous]] != payload {
				previous = next_node[previous]
			}
			node := next_node[previous]
			if node != SENTINEL do observed = 1
			if opcode == 4 && node != SENTINEL {
				next_node[previous] = next_node[node]
				if node == tail do tail = previous
				next_node[node] = free_head
				free_head = node
				count -= 1
			}
		} else if opcode == 6 {
			if payload != 0 do return -1
			observed = i64(count)
		} else if opcode == 7 || opcode == 8 {
			if payload < 0 || payload > 1_000_000 || count == 0 || payload >= i64(count) do return -1
			previous := SENTINEL
			for index := 0; index < int(payload); index += 1 { previous = next_node[previous] }
			node := next_node[previous]
			observed = node_value[node]
			if opcode == 8 {
				next_node[previous] = next_node[node]
				if node == tail do tail = previous
				next_node[node] = free_head
				free_head = node
				count -= 1
			}
		} else { return -1 }
		if returns_value do checksum += i64(operation + 1) * (observed + VALUE_OFFSET)
	}
	node := next_node[SENTINEL]
	index := 0
	for node != SENTINEL {
		checksum += i64(operation_count + index + 1) * (node_value[node] + VALUE_OFFSET)
		node = next_node[node]
		index += 1
	}
	return checksum
}
