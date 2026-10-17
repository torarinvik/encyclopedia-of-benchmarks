package table_heap

import "core:c"

MAX_ITEMS :: 64
MAX_OPERATIONS :: 256
MAX_INPUT_LENGTH :: 1155
MAP_CAPACITY :: 128
NIL_SENTINEL :: i64(-9223372036854775807 - 1)

Map_Entry :: struct {
	id:       i32,
	priority: i32,
	index:    int,
	state:    u8,
}

map_hash :: proc "contextless" (id: i32) -> int {
	bits := transmute(u32)id
	return int((u64(bits) * 2654435761) & u64(MAP_CAPACITY - 1))
}

map_find :: proc "contextless" (map: [^]Map_Entry, id: i32) -> int {
	slot := map_hash(id)
	for _ in 0 ..< MAP_CAPACITY {
		if map[slot].state == 0 do return MAP_CAPACITY
		if map[slot].state == 1 && map[slot].id == id do return slot
		slot = (slot + 1) & (MAP_CAPACITY - 1)
	}
	return MAP_CAPACITY
}

map_insert :: proc "contextless" (map: [^]Map_Entry, id: i32, priority: i32, index: int) -> int {
	slot := map_hash(id)
	tombstone := MAP_CAPACITY
	for _ in 0 ..< MAP_CAPACITY {
		if map[slot].state == 2 && tombstone == MAP_CAPACITY do tombstone = slot
		if map[slot].state == 0 {
			if tombstone != MAP_CAPACITY do slot = tombstone
			map[slot] = Map_Entry{id=id, priority=priority, index=index, state=1}
			return slot
		}
		if map[slot].state == 1 && map[slot].id == id do return slot
		slot = (slot + 1) & (MAP_CAPACITY - 1)
	}
	if tombstone != MAP_CAPACITY {
		map[tombstone] = Map_Entry{id=id, priority=priority, index=index, state=1}
		return tombstone
	}
	return MAP_CAPACITY
}

map_remove :: proc "contextless" (map: [^]Map_Entry, slot: int) {
	map[slot].state = 2
}

priority_of :: proc "contextless" (map: [^]Map_Entry, id: i32) -> i32 {
	return map[map_find(map, id)].priority
}

swap_ids :: proc "contextless" (heap: [^]i32, map: [^]Map_Entry, a, b: int, update_indices: bool) {
	value := heap[a]
	heap[a] = heap[b]
	heap[b] = value
	if update_indices {
		map[map_find(map, heap[a])].index = a
		map[map_find(map, heap[b])].index = b
	}
}

heapify_down :: proc "contextless" (heap: [^]i32, count: int, map: [^]Map_Entry, start: int, update_indices: bool) {
	index := start
	for {
		left := index * 2 + 1
		if left >= count do return
		child := left + 1
		if child >= count || priority_of(map, heap[left]) < priority_of(map, heap[child]) do child = left
		if priority_of(map, heap[child]) >= priority_of(map, heap[index]) do return
		swap_ids(heap, map, index, child, update_indices)
		index = child
	}
}

heapify_up :: proc "contextless" (heap: [^]i32, map: [^]Map_Entry, start: int) {
	index := start
	for index > 0 {
		parent := (index - 1) / 2
		if priority_of(map, heap[index]) >= priority_of(map, heap[parent]) do return
		swap_ids(heap, map, index, parent, true)
		index = parent
	}
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits >> u32(8*byte))
	}
}

@(export)
table_heap :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_ITEMS do return -1
	initial := int(input[0])
	operation_index := 1 + 2*initial
	if int(length) <= operation_index || input[operation_index] < 0 || input[operation_index] > MAX_OPERATIONS do return -1
	operation_count := int(input[operation_index])
	if int(length) != 2 + 2*initial + 4*operation_count || int(length) > MAX_INPUT_LENGTH-1 do return -1

	heap: [MAX_ITEMS]i32
	map: [MAP_CAPACITY]Map_Entry
	count := initial
	for i := 0; i < initial; i += 1 {
		id_value, priority_value := input[1+2*i], input[2+2*i]
		if id_value < -2147483648 || id_value > 2147483647 || priority_value < -2147483648 || priority_value > 2147483647 do return -1
		id := i32(id_value)
		if map_find(&map[0], id) != MAP_CAPACITY do return -1
		heap[i] = id
		if map_insert(&map[0], id, i32(priority_value), 0) == MAP_CAPACITY do return -1
	}
	for parent := count/2; parent > 0; parent -= 1 {
		heapify_down(&heap[0], count, &map[0], parent-1, false)
	}
	for i := 0; i < count; i += 1 {
		map[map_find(&map[0], heap[i])].index = i
	}

	answers: [MAX_OPERATIONS]i64
	cursor := operation_index + 1
	for oi := 0; oi < operation_count; oi += 1 {
		op, a, b, c_value := input[cursor], input[cursor+1], input[cursor+2], input[cursor+3]
		cursor += 4
		if op < 0 || op > 9 do return -1
		if op == 0 {
			if a < -2147483648 || a > 2147483647 || b < -2147483648 || b > 2147483647 || c_value != 0 || count == MAX_ITEMS do return -1
			id := i32(a)
			if map_find(&map[0], id) != MAP_CAPACITY do return -1
			heap[count] = id
			if map_insert(&map[0], id, i32(b), count) == MAP_CAPACITY do return -1
			count += 1
			heapify_up(&heap[0], &map[0], count-1)
			answers[oi] = NIL_SENTINEL
		} else if op == 1 {
			if a != 0 || b != 0 || c_value != 0 do return -1
			answers[oi] = if count == 0 do NIL_SENTINEL else i64(heap[0])
		} else if op == 2 {
			if a != 0 || b != 0 || c_value != 0 || count == 0 do return -1
			removed := heap[0]
			answers[oi] = i64(removed)
			old_slot := map_find(&map[0], removed)
			swap_ids(&heap[0], &map[0], 0, count-1, true)
			count -= 1
			map_remove(&map[0], old_slot)
			if count > 0 do heapify_down(&heap[0], count, &map[0], 0, true)
		} else if op == 3 || op == 4 {
			if a != 0 || b != 0 || c_value != 0 do return -1
			answers[oi] = if op == 3 do i64(count) else if count == 0 do 1 else 0
		} else if op == 5 {
			if a < -2147483648 || a > 2147483647 || b != 0 || c_value != 0 do return -1
			slot := map_find(&map[0], i32(a))
			answers[oi] = if slot == MAP_CAPACITY do NIL_SENTINEL else i64(map[slot].index+1)
		} else if op == 6 || op == 7 {
			if a < -2147483648 || a > 2147483647 || b < -2147483648 || b > 2147483647 || c_value != 0 do return -1
			slot := map_find(&map[0], i32(a))
			if slot == MAP_CAPACITY || (op == 6 && b > i64(map[slot].priority)) || (op == 7 && b < i64(map[slot].priority)) do return -1
			map[slot].priority = i32(b)
			if op == 6 do heapify_up(&heap[0], &map[0], map[slot].index)
			else do heapify_down(&heap[0], count, &map[0], map[slot].index, true)
			answers[oi] = NIL_SENTINEL
		} else if op == 8 {
			if a < -2147483648 || a > 2147483647 || b < -2147483648 || b > 2147483647 || c_value < -2147483648 || c_value > 2147483647 do return -1
			old_id, new_id := i32(a), i32(b)
			old_slot, new_slot := map_find(&map[0], old_id), map_find(&map[0], new_id)
			if old_slot == MAP_CAPACITY || (new_slot != MAP_CAPACITY && (new_id != old_id || c_value != i64(map[old_slot].priority))) do return -1
			if new_slot == MAP_CAPACITY {
				index, old_priority := map[old_slot].index, map[old_slot].priority
				map_insert(&map[0], new_id, i32(c_value), index)
				heap[index] = new_id
				if i32(c_value) < old_priority do heapify_up(&heap[0], &map[0], index)
				else do heapify_down(&heap[0], count, &map[0], index, true)
				map_remove(&map[0], old_slot)
			}
			answers[oi] = NIL_SENTINEL
		} else {
			if a < -2147483648 || a > 2147483647 || b != 0 || c_value != 0 do return -1
			slot := map_find(&map[0], i32(a))
			if slot == MAP_CAPACITY do return -1
			index, removed_priority := map[slot].index, map[slot].priority
			count -= 1
			if index != count {
				heap[index] = heap[count]
				map[map_find(&map[0], heap[index])].index = index
				if priority_of(&map[0], heap[index]) < removed_priority do heapify_up(&heap[0], &map[0], index)
				else do heapify_down(&heap[0], count, &map[0], index, true)
			}
			map_remove(&map[0], slot)
			answers[oi] = NIL_SENTINEL
		}
	}

	output_bytes := operation_count*8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for i := 0; i < operation_count; i += 1 {
		store_i64_le(output, i*8, answers[i])
	}
	return i64(output_bytes)
}
