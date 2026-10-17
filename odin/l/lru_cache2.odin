package lru_cache2

import "core:c"

MAX_CAPACITY :: 64
MAX_OPERATIONS :: 256
MAP_SIZE :: 1024
MAX_INPUT_LENGTH :: 771
PUT_SENTINEL :: i64(-9223372036854775807 - 1)

Cache_Node :: struct { key: i32, value: i32, previous: int, next: int }
Map_Entry :: struct { key: i32, node: int, state: u8 }

map_hash :: proc "contextless" (key: i32) -> int {
	bits := transmute(u32)key
	return int((u64(bits) * 2654435761) & 1023)
}

map_find :: proc "contextless" (map: [^]Map_Entry, key: i32) -> int {
	slot := map_hash(key)
	for _ in 0 ..< MAP_SIZE {
		if map[slot].state == 0 do return -1
		if map[slot].state == 1 && map[slot].key == key do return map[slot].node
		slot = (slot + 1) & (MAP_SIZE - 1)
	}
	return -1
}

map_insert :: proc "contextless" (map: [^]Map_Entry, key: i32, node: int) -> bool {
	slot, tombstone := map_hash(key), MAP_SIZE
	for _ in 0 ..< MAP_SIZE {
		if map[slot].state == 1 && map[slot].key == key do return false
		if map[slot].state == 2 && tombstone == MAP_SIZE do tombstone = slot
		if map[slot].state == 0 {
			if tombstone != MAP_SIZE do slot = tombstone
			map[slot] = Map_Entry{key=key, node=node, state=1}
			return true
		}
		slot = (slot + 1) & (MAP_SIZE - 1)
	}
	if tombstone != MAP_SIZE {
		map[tombstone] = Map_Entry{key=key, node=node, state=1}
		return true
	}
	return false
}

map_remove :: proc "contextless" (map: [^]Map_Entry, key: i32) {
	slot := map_hash(key)
	for _ in 0 ..< MAP_SIZE {
		if map[slot].state == 0 do return
		if map[slot].state == 1 && map[slot].key == key { map[slot].state = 2; return }
		slot = (slot + 1) & (MAP_SIZE - 1)
	}
}

unlink_node :: proc "contextless" (nodes: [^]Cache_Node, head, tail: ^int, node: int) {
	previous, next := nodes[node].previous, nodes[node].next
	if previous < 0 do head^ = next else do nodes[previous].next = next
	if next < 0 do tail^ = previous else do nodes[next].previous = previous
}

link_head :: proc "contextless" (nodes: [^]Cache_Node, head, tail: ^int, node: int) {
	nodes[node].previous = -1
	nodes[node].next = head^
	if head^ < 0 do tail^ = node else do nodes[head^].previous = node
	head^ = node
}

promote :: proc "contextless" (nodes: [^]Cache_Node, head, tail: ^int, node: int) {
	if head^ == node do return
	unlink_node(nodes, head, tail, node)
	link_head(nodes, head, tail, node)
}

store_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte in 0 ..< 8 { output[offset+byte] = u8((bits >> (8*byte)) & 255) }
}

@(export)
lru_cache2 :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 2 || input[0] > MAX_CAPACITY || input[1] < 0 || input[1] > MAX_OPERATIONS do return -1
	cache_capacity, operation_count := int(input[0]), int(input[1])
	if length != 2 + 3*operation_count do return -1

	var nodes: [MAX_CAPACITY]Cache_Node
	var map: [MAP_SIZE]Map_Entry
	var seen_put_keys: [MAX_OPERATIONS]i32
	seen_count, head, tail, node_count := 0, -1, -1, 0
	var results: [MAX_OPERATIONS]i64
	for operation in 0 ..< operation_count {
		base := 2 + operation*3
		opcode, first, second := input[base], input[base+1], input[base+2]
		if opcode < 0 || opcode > 4 do return -1
		if opcode == 0 {
			if first < -2147483648 || first > 2147483647 || second < -2147483648 || second > 2147483647 do return -1
			key := i32(first)
			for index in 0 ..< seen_count { if seen_put_keys[index] == key do return -1 }
			seen_put_keys[seen_count] = key
			seen_count += 1
			node: int
			if node_count < cache_capacity { node = node_count; node_count += 1 }
			else { node = tail; map_remove(&map[0], nodes[node].key); unlink_node(&nodes[0], &head, &tail, node) }
			nodes[node].key, nodes[node].value = key, i32(second)
			if !map_insert(&map[0], key, node) do return -1
			link_head(&nodes[0], &head, &tail, node)
			results[operation] = PUT_SENTINEL
		} else if opcode == 1 {
			if first < -2147483648 || first > 2147483647 || second != 0 do return -1
			node := map_find(&map[0], i32(first))
			if node < 0 do return -1
			promote(&nodes[0], &head, &tail, node)
			results[operation] = i64(nodes[node].value)
		} else {
			if first != 0 || second != 0 do return -1
			if opcode == 2 do results[operation] = i64(node_count)
			else if opcode == 3 do results[operation] = i64(cache_capacity)
			else do results[operation] = if node_count == 0 then 1 else 0
		}
	}
	output_bytes := operation_count*8
	if output == nil || capacity < output_bytes do return -2
	for operation in 0 ..< operation_count { store_i64(&output[0], operation*8, results[operation]) }
	return i64(output_bytes)
}
