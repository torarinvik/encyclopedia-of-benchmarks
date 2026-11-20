package erasable_priority_queue_trace

import "core:c"

MAX_Q :: 63
MAX_PARSEABLE_INPUT_LENGTH :: 128
VALUE_OFFSET :: 100
VALUE_COUNT :: 201

entry_less :: proc "contextless" (left, right: int, values: [^]i64) -> bool {
	return values[left] < values[right] || (values[left] == values[right] && left < right)
}

heap_push :: proc "contextless" (heap: [^]int, size: ^int, item: int, values: [^]i64) {
	at := size^
	size^ += 1
	for at > 0 {
		parent := (at - 1) / 2
		if !entry_less(item, heap[parent], values) do break
		heap[at] = heap[parent]
		at = parent
	}
	heap[at] = item
}

heap_pop :: proc "contextless" (heap: [^]int, size: ^int, values: [^]i64) -> int {
	result := heap[0]
	size^ -= 1
	if size^ == 0 do return result
	last := heap[size^]
	at := 0
	for {
		child := 2 * at + 1
		if child >= size^ do break
		if child + 1 < size^ && entry_less(heap[child + 1], heap[child], values) do child += 1
		if !entry_less(heap[child], last, values) do break
		heap[at] = heap[child]
		at = child
	}
	heap[at] = last
	return result
}

normalize :: proc "contextless" (live: [^]int, live_size: ^int,
	deleted: [^]int, deleted_size: ^int, values: [^]i64) {
	for live_size^ > 0 && deleted_size^ > 0 && live[0] == deleted[0] {
		_ = heap_pop(live, live_size, values)
		_ = heap_pop(deleted, deleted_size, values)
	}
}

@(export)
erasable_priority_queue_trace :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	q_word := input[0]
	if q_word < 0 || q_word > MAX_Q do return -1
	q := int(q_word)
	if int(length) != 1 + 2*q do return -1

	values: [MAX_Q]i64
	counts: [VALUE_COUNT]int
	active: [MAX_Q]bool
	live: [MAX_Q]int
	deleted: [MAX_Q]int
	live_size, deleted_size, inserted := 0, 0, 0
	score := i64(0)

	for operation := 0; operation < q; operation += 1 {
		opcode_word := input[1+2*operation]
		operand_word := input[2+2*operation]
		if opcode_word < 0 || opcode_word > 3 || operand_word < -VALUE_OFFSET || operand_word > VALUE_OFFSET do return -1
		opcode := int(opcode_word)
		operand := int(operand_word)
		normalize(&live[0], &live_size, &deleted[0], &deleted_size, &values[0])
		response := 0
		if opcode == 0 {
			id := inserted
			inserted += 1
			values[id] = operand_word
			active[id] = true
			counts[operand+VALUE_OFFSET] += 1
			heap_push(&live[0], &live_size, id, &values[0])
			normalize(&live[0], &live_size, &deleted[0], &deleted_size, &values[0])
		} else if opcode == 1 {
			key := operand + VALUE_OFFSET
			if counts[key] == 0 do return -1
			id := -1
			for candidate := 0; candidate < inserted; candidate += 1 {
				if active[candidate] && values[candidate] == operand_word {
					id = candidate
					break
				}
			}
			if id < 0 do return -1
			active[id] = false
			counts[key] -= 1
			heap_push(&deleted[0], &deleted_size, id, &values[0])
			response = 1
			normalize(&live[0], &live_size, &deleted[0], &deleted_size, &values[0])
		} else if opcode == 2 {
			if operand_word != 0 do return -1
			response = -101
			if live_size > 0 do response = int(values[live[0]])
		} else {
			if operand_word != 0 || live_size == 0 do return -1
			id := heap_pop(&live[0], &live_size, &values[0])
			active[id] = false
			counts[int(values[id])+VALUE_OFFSET] -= 1
			response = int(values[id])
		}
		token := opcode_word*202 + i64(response) + 101
		score += i64(operation+1) * token
	}
	return score
}
