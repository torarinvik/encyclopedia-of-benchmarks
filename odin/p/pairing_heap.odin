package pairing_heap

import "core:c"

MAX_ITEMS :: 128
MAX_PARSEABLE_INPUT_LENGTH :: MAX_ITEMS + 2
FNV_OFFSET_BASIS :: u64(14_695_981_039_346_656_037)
FNV_PRIME :: u64(1_099_511_628_211)
MASK_63 :: u64(0x7fff_ffff_ffff_ffff)

Pairing_Node :: struct {
	key: i32,
	first_child: int,
	next_sibling: int,
}

meld :: proc "contextless" (first_root, second_root: int, nodes: [^]Pairing_Node) -> int {
	if first_root < 0 do return second_root
	if second_root < 0 do return first_root
	first := first_root
	second := second_root
	if nodes[second].key < nodes[first].key {
		temporary := first
		first = second
		second = temporary
	}
	nodes[second].next_sibling = nodes[first].first_child
	nodes[first].first_child = second
	nodes[first].next_sibling = -1
	return first
}

hash_key :: proc "contextless" (hash_value: u64, key: i32) -> u64 {
	hash := hash_value
	bits := u32(key)
	for byte := 0; byte < 4; byte += 1 {
		hash = (hash ^ u64(u8(bits >> u32(byte * 8)))) * FNV_PRIME
	}
	return hash
}

@(export)
pairing_heap :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	raw_count := values[0]
	if raw_count < 2 || raw_count > MAX_ITEMS do return -1
	count := int(raw_count)
	if length != c.size_t(1 + count) do return -1

	nodes: [MAX_ITEMS]Pairing_Node
	for index := 0; index < count; index += 1 {
		value := values[1 + index]
		if value < -2_147_483_648 || value > 2_147_483_647 do return -1
		for previous := 0; previous < index; previous += 1 {
			if values[1 + previous] == value do return -1
		}
		nodes[index].key = i32(value)
		nodes[index].first_child = -1
		nodes[index].next_sibling = -1
	}

	root := -1
	for index := 0; index < count; index += 1 {
		root = meld(root, index, &nodes[0])
	}

	hash := FNV_OFFSET_BASIS
	for extraction := 0; extraction < count - 1; extraction += 1 {
		removed := root
		hash = hash_key(hash, nodes[removed].key)
		forest: [MAX_ITEMS]int
		paired: [MAX_ITEMS]int
		forest_count := 0
		child := nodes[removed].first_child
		nodes[removed].first_child = -1
		for child >= 0 {
			next := nodes[child].next_sibling
			nodes[child].next_sibling = -1
			forest[forest_count] = child
			forest_count += 1
			child = next
		}
		paired_count := 0
		index := 0
		for index < forest_count {
			right := -1
			if index + 1 < forest_count do right = forest[index + 1]
			paired[paired_count] = meld(forest[index], right, &nodes[0])
			paired_count += 1
			index += 2
		}
		rebuilt := -1
		for paired_count > 0 {
			paired_count -= 1
			rebuilt = meld(rebuilt, paired[paired_count], &nodes[0])
		}
		root = rebuilt
	}
	return i64(hash & MASK_63)
}
