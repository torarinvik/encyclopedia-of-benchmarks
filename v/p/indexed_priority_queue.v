module indexed_priority_queue

const max_events = 256
const max_active = 64
const max_input_values = 1538

fn store_i64_le(mut output &u8, position int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[position + byte] = u8(bits & 0xff) }
		bits >>= 8
	}
}

fn key_in_use(heap_ids &i64, heap_keys &i64, size int, key i64, except_id i64) bool {
	unsafe {
		for index in 0 .. size {
			if heap_ids[index] != except_id && heap_keys[index] == key { return true }
		}
	}
	return false
}

fn sift_up(mut heap_ids [max_active]i64, mut heap_keys [max_active]i64,
		mut positions [max_active]int, index_value int) bool {
	mut index := index_value
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

fn sift_down(mut heap_ids [max_active]i64, mut heap_keys [max_active]i64,
		mut positions [max_active]int, size int, index_value int) {
	mut index := index_value
	item_id, item_key := heap_ids[index], heap_keys[index]
	half := size / 2
	for index < half {
		mut child := index * 2 + 1
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

fn remove_at(mut size int, mut heap_ids [max_active]i64, mut heap_keys [max_active]i64,
		mut positions [max_active]int, index int) {
	new_size := size - 1
	removed_id := heap_ids[index]
	moved_id, moved_key := heap_ids[new_size], heap_keys[new_size]
	size = new_size
	positions[int(removed_id)] = -1
	if index == new_size { return }
	heap_ids[index], heap_keys[index] = moved_id, moved_key
	positions[int(moved_id)] = index
	if !sift_up(mut heap_ids, mut heap_keys, mut positions, index) {
		sift_down(mut heap_ids, mut heap_keys, mut positions, size, index)
	}
}

@[export: 'indexed_priority_queue']
pub fn indexed_priority_queue(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 1 || length > max_input_values { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > max_events { return -1 }
		count := int(values[0])
		if length != usize(1 + 6 * count) { return -1 }
		if count == 0 { return 0 }

		mut heap_ids := [max_active]i64{}
		mut heap_keys := [max_active]i64{}
		mut positions := [max_active]int{}
		mut records := [max_events][6]i64{}
		for id in 0 .. max_active { positions[id] = -1 }
		mut size := 0

		for event_index in 0 .. count {
			start := 1 + event_index * 6
			opcode, element_id, key := values[start], values[start + 1], values[start + 2]
			if values[start + 3] != 0 || values[start + 4] != 0 || values[start + 5] != 0 { return -1 }
			mut status, result_id, result_key := i64(1), i64(0), i64(0)

			if opcode == 0 {
				if element_id < 0 || element_id >= max_active || key < -2147483648 || key > 2147483647 { return -1 }
				id := int(element_id)
				if positions[id] >= 0 || size >= max_active || key_in_use(&heap_ids[0], &heap_keys[0], size, key, -1) { return -1 }
				heap_ids[size], heap_keys[size] = element_id, key
				positions[id] = size
				size++
				_ = sift_up(mut heap_ids, mut heap_keys, mut positions, size - 1)
			} else if opcode == 1 || opcode == 2 {
				if element_id != 0 || key != 0 { return -1 }
				if size == 0 { status = 0 } else {
					result_id, result_key = heap_ids[0], heap_keys[0]
					if opcode == 2 { remove_at(mut size, mut heap_ids, mut heap_keys, mut positions, 0) }
				}
			} else if opcode == 3 || opcode == 4 {
				if element_id < 0 || element_id >= max_active || key != 0 { return -1 }
				position := positions[int(element_id)]
				if position >= 0 { status = 1 } else { status = 0 }
				if opcode == 3 && position >= 0 { remove_at(mut size, mut heap_ids, mut heap_keys, mut positions, position) }
			} else if opcode >= 5 && opcode <= 7 {
				if element_id < 0 || element_id >= max_active || key < -2147483648 || key > 2147483647 { return -1 }
				position := positions[int(element_id)]
				if position < 0 { return -1 }
				old_key := heap_keys[position]
				if (opcode == 6 && key >= old_key) || (opcode == 7 && key <= old_key) ||
					key_in_use(&heap_ids[0], &heap_keys[0], size, key, element_id) { return -1 }
				heap_keys[position] = key
				if opcode == 6 { _ = sift_up(mut heap_ids, mut heap_keys, mut positions, position) }
				else if opcode == 7 { sift_down(mut heap_ids, mut heap_keys, mut positions, size, position) }
				else if !sift_up(mut heap_ids, mut heap_keys, mut positions, position) { sift_down(mut heap_ids, mut heap_keys, mut positions, size, position) }
			} else if opcode == 8 || opcode == 9 || opcode == 10 {
				if element_id != 0 || key != 0 { return -1 }
				if opcode == 8 {
					for index in 0 .. size { positions[int(heap_ids[index])] = -1 }
					size = 0
				} else if opcode == 9 { result_id = i64(size) }
				else if size == 0 { result_id = 1 } else { result_id = 0 }
			} else { return -1 }

			mut minimum_id, minimum_key := i64(0), i64(0)
			if size > 0 { minimum_id, minimum_key = heap_ids[0], heap_keys[0] }
			records[event_index] = [6]i64{status, result_id, result_key, i64(size), minimum_id, minimum_key}
		}

		required := count * 48
		if unsafe { output == nil } || output_capacity < usize(required) { return -2 }
		for event_index in 0 .. count {
			for field in 0 .. 6 { store_i64_le(mut output, event_index * 48 + field * 8, records[event_index][field]) }
		}
		return i64(required)
	}
}
