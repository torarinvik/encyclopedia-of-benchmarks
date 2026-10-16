package heap_generic

import "core:c"

MAX_OPERATIONS :: 512
MAX_ITEMS :: 128
ID_CAPACITY :: 4096
MAX_INPUT_LENGTH :: 1537
FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

hash_byte :: proc(hash: u64, byte: u8) -> u64 {
	return (hash ^ u64(byte)) * FNV_PRIME
}

hash_i32 :: proc(hash_value: u64, value: i64) -> u64 {
	hash := hash_value
	bits := u32(value)
	for shift := 0; shift < 32; shift += 8 {
		hash = hash_byte(hash, u8(bits >> shift))
	}
	return hash
}

swap_items :: proc(ids, priorities: [^]i64, positions: [^]int, first, second: int) {
	temporary := ids[first]; ids[first] = ids[second]; ids[second] = temporary
	temporary = priorities[first]; priorities[first] = priorities[second]; priorities[second] = temporary
	positions[ids[first]] = first
	positions[ids[second]] = second
}

heapify_up :: proc(ids, priorities: [^]i64, positions: [^]int, start: int) {
	index := start
	for index > 0 {
		parent := (index - 1) / 2
		if priorities[index] <= priorities[parent] do break
		swap_items(ids, priorities, positions, index, parent)
		index = parent
	}
}

heapify_down :: proc(ids, priorities: [^]i64, positions: [^]int, heap_size, start: int) {
	index := start
	for {
		best := index
		left := 2 * index + 1
		right := left + 1
		if left < heap_size && priorities[left] > priorities[best] do best = left
		if right < heap_size && priorities[right] > priorities[best] do best = right
		if best == index do return
		swap_items(ids, priorities, positions, index, best)
		index = best
	}
}

erase_item :: proc(ids, priorities: [^]i64, positions: [^]int, heap_size: ^int, item_id: int) {
	index := positions[item_id]
	last := heap_size^ - 1
	positions[item_id] = -1
	if index != last {
		ids[index] = ids[last]
		priorities[index] = priorities[last]
		positions[ids[index]] = index
	}
	heap_size^ = last
	if index < heap_size^ {
		heapify_up(ids, priorities, positions, index)
		heapify_down(ids, priorities, positions, heap_size^, index)
	}
}

@(export)
heap_generic :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	operation_count_value := values[0]
	if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS ||
		length != c.size_t(1 + 3 * operation_count_value) do return -1

	ids: [MAX_ITEMS]i64
	priorities: [MAX_ITEMS]i64
	positions: [ID_CAPACITY]int
	used_ids: [ID_CAPACITY]bool
	for index := 0; index < ID_CAPACITY; index += 1 {
		positions[index] = -1
		used_ids[index] = false
	}
	heap_size := 0
	hash := FNV_OFFSET

	for operation := 0; operation < int(operation_count_value); operation += 1 {
		opcode := values[1 + 3 * operation]
		item_id := values[2 + 3 * operation]
		priority := values[3 + 3 * operation]
		present := false
		returned_id, returned_priority: i64 = 0, 0

		if opcode == 0 {
			if item_id < 0 || item_id >= ID_CAPACITY || priority < -2147483648 || priority > 2147483647 ||
				used_ids[item_id] || heap_size >= MAX_ITEMS do return -1
			for index := 0; index < heap_size; index += 1 {
				if priorities[index] == priority do return -1
			}
			used_ids[item_id] = true
			ids[heap_size] = item_id
			priorities[heap_size] = priority
			positions[item_id] = heap_size
			heap_size += 1
			heapify_up(&ids[0], &priorities[0], &positions[0], heap_size - 1)
		} else if opcode == 1 || opcode == 2 {
			if item_id != 0 || priority != 0 do return -1
			if heap_size > 0 {
				present = true
				returned_id, returned_priority = ids[0], priorities[0]
				if opcode == 2 do erase_item(&ids[0], &priorities[0], &positions[0], &heap_size, int(returned_id))
			}
		} else if opcode == 3 {
			if item_id < 0 || item_id >= ID_CAPACITY || priority < -2147483648 || priority > 2147483647 ||
				positions[item_id] < 0 do return -1
			index := positions[item_id]
			for other := 0; other < heap_size; other += 1 {
				if other != index && priorities[other] == priority do return -1
			}
			priorities[index] = priority
			heapify_up(&ids[0], &priorities[0], &positions[0], index)
			heapify_down(&ids[0], &priorities[0], &positions[0], heap_size, index)
		} else if opcode == 4 {
			if item_id < 0 || item_id >= ID_CAPACITY || priority != 0 || positions[item_id] < 0 do return -1
			erase_item(&ids[0], &priorities[0], &positions[0], &heap_size, int(item_id))
		} else do return -1

		hash = hash_byte(hash, u8(opcode))
		hash = hash_byte(hash, u8(b32(present)))
		if present {
			hash = hash_i32(hash, returned_id)
			hash = hash_i32(hash, returned_priority)
		}
	}
	return i64(hash)
}
