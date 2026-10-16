module min_max_heap_double_ended

import core:c

const max_initial = 64
const max_operations = 128
const max_heap_size = 192
const invalid_result = i64(-1)
const capacity_result = i64(-2)

fn is_min_level(index int) bool {
	mut value := index + 1
	mut depth := 0
	for value > 1 { value >>= 1; depth++ }
	return depth % 2 == 0
}

fn best_descendant(heap []i64, count int, index int, find_min bool) int {
	mut best := -1
	for offset in 0 .. 6 {
		candidate := if offset < 2 { 2 * index + 1 + offset } else { 4 * index + 1 + offset }
		if candidate >= count { break }
		if best < 0 || (if find_min { heap[candidate] < heap[best] } else { heap[candidate] > heap[best] }) { best = candidate }
	}
	return best
}

fn push_down(mut heap []i64, count int, start int, find_min bool) {
	mut index := start
	for index < count {
		best := best_descendant(heap, count, index, find_min)
		if best < 0 { return }
		grandchild := best > 2 && (best - 3) / 4 == index
		improves := if find_min { heap[best] < heap[index] } else { heap[best] > heap[index] }
		if grandchild {
			if !improves { return }
			heap[index], heap[best] = heap[best], heap[index]
			parent := (best - 1) / 2
			violation := if find_min { heap[best] > heap[parent] } else { heap[best] < heap[parent] }
			if violation { heap[best], heap[parent] = heap[parent], heap[best] }
			index = best
		} else {
			if improves { heap[index], heap[best] = heap[best], heap[index] }
			return
		}
	}
}

fn push_up_min(mut heap []i64, start int) {
	mut index := start
	for index > 2 {
		grandparent := (index - 3) / 4
		if heap[index] >= heap[grandparent] { return }
		heap[index], heap[grandparent] = heap[grandparent], heap[index]
		index = grandparent
	}
}

fn push_up_max(mut heap []i64, start int) {
	mut index := start
	for index > 2 {
		grandparent := (index - 3) / 4
		if heap[index] <= heap[grandparent] { return }
		heap[index], heap[grandparent] = heap[grandparent], heap[index]
		index = grandparent
	}
}

fn push_up(mut heap []i64, index int) {
	if index == 0 { return }
	parent := (index - 1) / 2
	if is_min_level(index) {
		if heap[index] > heap[parent] {
			heap[index], heap[parent] = heap[parent], heap[index]
			push_up_max(mut heap, parent)
		} else { push_up_min(mut heap, index) }
	} else if heap[index] < heap[parent] {
		heap[index], heap[parent] = heap[parent], heap[index]
		push_up_min(mut heap, parent)
	} else { push_up_max(mut heap, index) }
}

fn add_value(mut heap []i64, mut count int, value i64) {
	index := count
	count++
	heap[index] = value
	push_up(mut heap, index)
}

fn max_index(heap []i64, count int) int {
	if count < 2 { return 0 }
	if count == 2 { return 1 }
	return if heap[1] > heap[2] { 1 } else { 2 }
}

fn extract_at(mut heap []i64, mut count int, index int) i64 {
	result := heap[index]
	count--
	if index != count { heap[index] = heap[count] }
	if count > 0 && index < count { push_down(mut heap, count, index, is_min_level(index)) }
	return result
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}

fn insertion_sort(mut values []i64, count int) {
	for index in 1 .. count {
		value := values[index]
		mut position := index
		for position > 0 && values[position - 1] > value {
			values[position] = values[position - 1]
			position--
		}
		values[position] = value
	}
}

@[export: 'min_max_heap_double_ended']
pub fn min_max_heap_double_ended(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return invalid_result }
	unsafe {
		if input[0] < 0 || input[0] > max_initial { return invalid_result }
		initial_count := int(input[0])
		if length < usize(initial_count + 2) { return invalid_result }
		operation_value := input[initial_count + 1]
		if operation_value < 0 || operation_value > max_operations { return invalid_result }
		operation_count := int(operation_value)
		if length != usize(initial_count + 2 + 2 * operation_count) { return invalid_result }
		for index in 0 .. initial_count {
			if input[index + 1] < -2_147_483_648 || input[index + 1] > 2_147_483_647 { return invalid_result }
		}
		for op in 0 .. operation_count {
			opcode := input[initial_count + 2 + 2 * op]
			argument := input[initial_count + 3 + 2 * op]
			if opcode < 0 || opcode > 5 { return invalid_result }
			if opcode == 0 {
				if argument < -2_147_483_648 || argument > 2_147_483_647 { return invalid_result }
			} else if argument != 0 { return invalid_result }
		}
		mut heap := []i64{len: max_heap_size}
		mut count := initial_count
		for index in 0 .. initial_count { heap[index] = input[index + 1] }
		for index := initial_count / 2; index > 0; index-- { push_down(mut heap, count, index - 1, is_min_level(index - 1)) }
		mut events := []i64{len: max_operations}
		mut event_count := 0
		for op in 0 .. operation_count {
			opcode := input[initial_count + 2 + 2 * op]
			argument := input[initial_count + 3 + 2 * op]
			if opcode == 0 { add_value(mut heap, mut count, argument) }
			else if opcode == 1 || opcode == 3 {
				if count == 0 { return invalid_result }
				if opcode == 1 { events[event_count] = heap[0] } else { events[event_count] = extract_at(mut heap, mut count, 0) }
				event_count++
			} else if opcode == 2 || opcode == 4 {
				if count == 0 { return invalid_result }
				index := max_index(heap, count)
				if opcode == 2 { events[event_count] = heap[index] } else { events[event_count] = extract_at(mut heap, mut count, index) }
				event_count++
			} else { events[event_count] = i64(count); event_count++ }
		}
		mut sorted := heap.clone()
		insertion_sort(mut sorted, count)
		required := (2 + event_count + count) * 8
		if unsafe { output == nil } || capacity < usize(required) { return capacity_result }
		offset := 0
		write_i64_le(mut output, offset, i64(event_count)); offset += 8
		for index in 0 .. event_count { write_i64_le(mut output, offset, events[index]); offset += 8 }
		write_i64_le(mut output, offset, i64(count)); offset += 8
		for index in 0 .. count { write_i64_le(mut output, offset, sorted[index]); offset += 8 }
		return i64(required)
	}
}
