module lru_cache2

const max_capacity = 64
const max_operations = 256
const map_size = 1024
const put_sentinel = i64(-9223372036854775807 - 1)

struct CacheNode { key i32; value i32; previous int; next int }
struct MapEntry { key i32; node int; state u8 }

fn map_hash(key i32) int { return int((u64(u32(key)) * 2654435761) & 1023) }

fn map_find(map &[1024]MapEntry, key i32) int {
	start := map_hash(key)
	for probe in 0 .. map_size {
		index := (start + probe) & (map_size - 1)
		if map[index].state == 0 { return -1 }
		if map[index].state == 1 && map[index].key == key { return map[index].node }
	}
	return -1
}

fn map_insert(mut map [1024]MapEntry, key i32, node int) bool {
	mut slot := map_hash(key)
	mut tombstone := map_size
	for _ in 0 .. map_size {
		if map[slot].state == 1 && map[slot].key == key { return false }
		if map[slot].state == 2 && tombstone == map_size { tombstone = slot }
		if map[slot].state == 0 {
			if tombstone != map_size { slot = tombstone }
			map[slot] = MapEntry{key: key, node: node, state: 1}
			return true
		}
		slot = (slot + 1) & (map_size - 1)
	}
	if tombstone != map_size { map[tombstone] = MapEntry{key: key, node: node, state: 1}; return true }
	return false
}

fn map_remove(mut map [1024]MapEntry, key i32) {
	mut slot := map_hash(key)
	for _ in 0 .. map_size {
		if map[slot].state == 0 { return }
		if map[slot].state == 1 && map[slot].key == key { map[slot].state = 2; return }
		slot = (slot + 1) & (map_size - 1)
	}
}

fn unlink_node(mut nodes [64]CacheNode, mut head int, mut tail int, node int) {
	previous := nodes[node].previous
	next := nodes[node].next
	if previous < 0 { head = next } else { nodes[previous].next = next }
	if next < 0 { tail = previous } else { nodes[next].previous = previous }
}

fn link_head(mut nodes [64]CacheNode, mut head int, mut tail int, node int) {
	nodes[node].previous = -1
	nodes[node].next = head
	if head < 0 { tail = node } else { nodes[head].previous = node }
	head = node
}

fn promote(mut nodes [64]CacheNode, mut head int, mut tail int, node int) {
	if head == node { return }
	unlink_node(mut nodes, mut head, mut tail, node)
	link_head(mut nodes, mut head, mut tail, node)
}

fn store_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) } }
}

@[export: 'lru_cache2']
pub fn lru_cache2(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 771 { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > max_capacity || input[1] < 0 || input[1] > max_operations { return -1 }
		cache_capacity := int(input[0])
		operation_count := int(input[1])
		if length != usize(2 + operation_count * 3) { return -1 }
		mut nodes := [64]CacheNode{}
		mut map := [1024]MapEntry{}
		mut seen_put_keys := [256]i32{}
		mut seen_count := 0
		mut head := -1
		mut tail := -1
		mut node_count := 0
		mut results := [256]i64{}
		for operation in 0 .. operation_count {
			base := 2 + operation * 3
			opcode := input[base]
			first := input[base + 1]
			second := input[base + 2]
			if opcode < 0 || opcode > 4 { return -1 }
			if opcode == 0 {
				if first < -2147483648 || first > 2147483647 || second < -2147483648 || second > 2147483647 { return -1 }
				key := i32(first)
				for index in 0 .. seen_count { if seen_put_keys[index] == key { return -1 } }
				seen_put_keys[seen_count] = key
				seen_count++
				mut node := 0
				if node_count < cache_capacity { node = node_count; node_count++ }
				else { node = tail; map_remove(mut map, nodes[node].key); unlink_node(mut nodes, mut head, mut tail, node) }
				nodes[node].key = key
				nodes[node].value = i32(second)
				if !map_insert(mut map, key, node) { return -1 }
				link_head(mut nodes, mut head, mut tail, node)
				results[operation] = put_sentinel
			} else if opcode == 1 {
				if first < -2147483648 || first > 2147483647 || second != 0 { return -1 }
				node := map_find(&map, i32(first))
				if node < 0 { return -1 }
				promote(mut nodes, mut head, mut tail, node)
				results[operation] = i64(nodes[node].value)
			} else {
				if first != 0 || second != 0 { return -1 }
				if opcode == 2 { results[operation] = i64(node_count) }
				else if opcode == 3 { results[operation] = i64(cache_capacity) }
				else { results[operation] = if node_count == 0 { 1 } else { 0 } }
			}
		}
		output_bytes := operation_count * 8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for operation in 0 .. operation_count { store_i64(mut output, operation * 8, results[operation]) }
		return i64(output_bytes)
	}
}
