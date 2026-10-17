package indexed_priority_queue

import "core:c"

MAX_EVENTS :: 256
MAX_ACTIVE :: 64
MAX_INPUT_VALUES :: 1538

store_i64_le :: proc "contextless" (output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[position + byte] = u8((bits >> (byte * 8)) & 0xff) }
}

key_in_use :: proc "contextless" (heap_ids, heap_keys: [^]i64, size: int, key, except_id: i64) -> bool {
	for index := 0; index < size; index += 1 {
		if heap_ids[index] != except_id && heap_keys[index] == key { return true }
	}
	return false
}

sift_up :: proc "contextless" (heap_ids, heap_keys: [^]i64, positions: [^]int, index_value: int) -> bool {
	index := index_value
	original := index
	item_id, item_key := heap_ids[index], heap_keys[index]
	for index > 0 {
		parent := (index - 1) / 2
		if item_key >= heap_keys[parent] { break }
		heap_ids[index], heap_keys[index] = heap_ids[parent], heap_keys[parent]
		positions[int(heap_ids[index])] = index
		index = parent
	}
	heap_ids[index], heap_keys[index] = item_id, item_key
	positions[int(item_id)] = index
	return index != original
}

sift_down :: proc "contextless" (heap_ids, heap_keys: [^]i64, positions: [^]int, size, index_value: int) {
	index := index_value
	item_id, item_key := heap_ids[index], heap_keys[index]
	half := size / 2
	for index < half {
		child := index * 2 + 1
		right := child + 1
		if right < size && heap_keys[child] > heap_keys[right] { child = right }
		if item_key <= heap_keys[child] { break }
		heap_ids[index], heap_keys[index] = heap_ids[child], heap_keys[child]
		positions[int(heap_ids[index])] = index
		index = child
	}
	heap_ids[index], heap_keys[index] = item_id, item_key
	positions[int(item_id)] = index
}

remove_at :: proc "contextless" (size: ^int, heap_ids, heap_keys: [^]i64,
		positions: [^]int, index: int) {
	new_size := size^ - 1
	removed_id := heap_ids[index]
	moved_id, moved_key := heap_ids[new_size], heap_keys[new_size]
	size^ = new_size
	positions[int(removed_id)] = -1
	if index == new_size { return }
	heap_ids[index], heap_keys[index] = moved_id, moved_key
	positions[int(moved_id)] = index
	if !sift_up(heap_ids, heap_keys, positions, index) { sift_down(heap_ids, heap_keys, positions, size^, index) }
}

@(export)
indexed_priority_queue :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_INPUT_VALUES do return -1
	if values[0] < 0 || values[0] > MAX_EVENTS do return -1
	event_count := int(values[0])
	if int(length) != 1 + 6 * event_count do return -1
	if event_count == 0 do return 0

	heap_ids: [MAX_ACTIVE]i64
	heap_keys: [MAX_ACTIVE]i64
	positions: [MAX_ACTIVE]int
	records: [MAX_EVENTS][6]i64
	for id := 0; id < MAX_ACTIVE; id += 1 { positions[id] = -1 }
	size := 0

	for event_index := 0; event_index < event_count; event_index += 1 {
		start := 1 + event_index * 6
		opcode, element_id, key := values[start], values[start + 1], values[start + 2]
		if values[start + 3] != 0 || values[start + 4] != 0 || values[start + 5] != 0 do return -1
		status, result_id, result_key := i64(1), i64(0), i64(0)

		if opcode == 0 {
			if element_id < 0 || element_id >= MAX_ACTIVE || key < -2147483648 || key > 2147483647 do return -1
			id := int(element_id)
			if positions[id] >= 0 || size >= MAX_ACTIVE || key_in_use(&heap_ids[0], &heap_keys[0], size, key, -1) do return -1
			heap_ids[size], heap_keys[size] = element_id, key
			positions[id] = size
			size += 1
			_ = sift_up(&heap_ids[0], &heap_keys[0], &positions[0], size - 1)
		} else if opcode == 1 || opcode == 2 {
			if element_id != 0 || key != 0 do return -1
			if size == 0 { status = 0 } else {
				result_id, result_key = heap_ids[0], heap_keys[0]
				if opcode == 2 { remove_at(&size, &heap_ids[0], &heap_keys[0], &positions[0], 0) }
			}
		} else if opcode == 3 || opcode == 4 {
			if element_id < 0 || element_id >= MAX_ACTIVE || key != 0 do return -1
			position := positions[int(element_id)]
			if position >= 0 { status = 1 } else { status = 0 }
			if opcode == 3 && position >= 0 { remove_at(&size, &heap_ids[0], &heap_keys[0], &positions[0], position) }
		} else if opcode >= 5 && opcode <= 7 {
			if element_id < 0 || element_id >= MAX_ACTIVE || key < -2147483648 || key > 2147483647 do return -1
			position := positions[int(element_id)]
			if position < 0 do return -1
			old_key := heap_keys[position]
			if (opcode == 6 && key >= old_key) || (opcode == 7 && key <= old_key) ||
				key_in_use(&heap_ids[0], &heap_keys[0], size, key, element_id) do return -1
			heap_keys[position] = key
			if opcode == 6 { _ = sift_up(&heap_ids[0], &heap_keys[0], &positions[0], position) }
			else if opcode == 7 { sift_down(&heap_ids[0], &heap_keys[0], &positions[0], size, position) }
			else if !sift_up(&heap_ids[0], &heap_keys[0], &positions[0], position) { sift_down(&heap_ids[0], &heap_keys[0], &positions[0], size, position) }
		} else if opcode == 8 || opcode == 9 || opcode == 10 {
			if element_id != 0 || key != 0 do return -1
			if opcode == 8 {
				for index := 0; index < size; index += 1 { positions[int(heap_ids[index])] = -1 }
				size = 0
			} else if opcode == 9 { result_id = i64(size) }
			else if size == 0 { result_id = 1 } else { result_id = 0 }
		} else { return -1 }

		minimum_id, minimum_key := i64(0), i64(0)
		if size > 0 { minimum_id, minimum_key = heap_ids[0], heap_keys[0] }
		records[event_index] = [6]i64{status, result_id, result_key, i64(size), minimum_id, minimum_key}
	}

	required := event_count * 48
	if output == nil || output_capacity < c.size_t(required) do return -2
	for event_index := 0; event_index < event_count; event_index += 1 {
		for field := 0; field < 6; field += 1 { store_i64_le(output, event_index * 48 + field * 8, records[event_index][field]) }
	}
	return i64(required)
}
