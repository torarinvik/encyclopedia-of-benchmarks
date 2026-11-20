module erasable_priority_queue_trace

const (
	max_q = 63
	max_parseable_input_length = 128
	value_offset = 100
	value_count = 201
)

fn entry_less(left int, right int, values &[max_q]i64) bool {
	return values[left] < values[right] || (values[left] == values[right] && left < right)
}

fn heap_push(mut heap [max_q]int, mut size int, item int, values &[max_q]i64) {
	mut at := size
	size++
	for at > 0 {
		parent := (at - 1) / 2
		if !entry_less(item, heap[parent], values) { break }
		heap[at] = heap[parent]
		at = parent
	}
	heap[at] = item
}

fn heap_pop(mut heap [max_q]int, mut size int, values &[max_q]i64) int {
	result := heap[0]
	size--
	if size == 0 { return result }
	last := heap[size]
	mut at := 0
	for {
		mut child := 2 * at + 1
		if child >= size { break }
		if child + 1 < size && entry_less(heap[child + 1], heap[child], values) { child++ }
		if !entry_less(heap[child], last, values) { break }
		heap[at] = heap[child]
		at = child
	}
	heap[at] = last
	return result
}

fn normalize(mut live [max_q]int, mut live_size int,
	mut deleted [max_q]int, mut deleted_size int, values &[max_q]i64) {
	for live_size > 0 && deleted_size > 0 && live[0] == deleted[0] {
		_ = heap_pop(mut live, mut live_size, values)
		_ = heap_pop(mut deleted, mut deleted_size, values)
	}
}

@[export: 'erasable_priority_queue_trace']
pub fn erasable_priority_queue_trace(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_parseable_input_length { return -1 }
	unsafe {
		q_word := input[0]
		if q_word < 0 || q_word > max_q { return -1 }
		q := int(q_word)
		if length != usize(1 + 2 * q) { return -1 }

		mut values := [max_q]i64{}
		mut counts := [value_count]int{}
		mut active := [max_q]bool{}
		mut live := [max_q]int{}
		mut deleted := [max_q]int{}
		mut live_size, mut deleted_size, mut inserted := 0, 0, 0
		mut score := i64(0)

		for operation in 0 .. q {
			opcode_word := input[1 + 2 * operation]
			operand_word := input[2 + 2 * operation]
			if opcode_word < 0 || opcode_word > 3 || operand_word < -value_offset || operand_word > value_offset { return -1 }
			opcode := int(opcode_word)
			operand := int(operand_word)
			normalize(mut live, mut live_size, mut deleted, mut deleted_size, &values)
			mut response := 0
			if opcode == 0 {
				id := inserted
				inserted++
				values[id] = operand_word
				active[id] = true
				counts[operand + value_offset]++
				heap_push(mut live, mut live_size, id, &values)
				normalize(mut live, mut live_size, mut deleted, mut deleted_size, &values)
			} else if opcode == 1 {
				key := operand + value_offset
				if counts[key] == 0 { return -1 }
				mut id := -1
				for candidate in 0 .. inserted {
					if active[candidate] && values[candidate] == operand_word {
						id = candidate
						break
					}
				}
				if id < 0 { return -1 }
				active[id] = false
				counts[key]--
				heap_push(mut deleted, mut deleted_size, id, &values)
				response = 1
				normalize(mut live, mut live_size, mut deleted, mut deleted_size, &values)
			} else if opcode == 2 {
				if operand_word != 0 { return -1 }
				response = if live_size == 0 { -101 } else { int(values[live[0]]) }
			} else {
				if operand_word != 0 || live_size == 0 { return -1 }
				id := heap_pop(mut live, mut live_size, &values)
				active[id] = false
				counts[int(values[id]) + value_offset]--
				response = int(values[id])
			}
			token := opcode_word * 202 + i64(response) + 101
			score += i64(operation + 1) * token
		}
		return score
	}
}
