const max_items = 128
const max_parseable_input_length = max_items + 2
const fnv_offset_basis = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)
const mask_63 = u64(0x7fffffffffffffff)

struct PairingNode {
	key i32
	first_child int
	next_sibling int
}

fn meld(first_root int, second_root int, mut nodes [max_items]PairingNode) int {
	if first_root < 0 { return second_root }
	if second_root < 0 { return first_root }
	mut first := first_root
	mut second := second_root
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

fn hash_key(hash_value u64, key i32) u64 {
	mut hash := hash_value
	bits := u32(key)
	for byte in 0 .. 4 {
		hash = (hash ^ u64(u8(bits >> (byte * 8)))) * fnv_prime
	}
	return hash
}

@[export: 'pairing_heap']
pub fn pairing_heap(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > usize(max_parseable_input_length) { return -1 }
		raw_count := values[0]
		if raw_count < 2 || raw_count > max_items { return -1 }
		count := int(raw_count)
		if length != usize(1 + count) { return -1 }

		mut nodes := [max_items]PairingNode{}
		for index := 0; index < count; index++ {
			value := values[1 + index]
			if value < -2147483648 || value > 2147483647 { return -1 }
			for previous := 0; previous < index; previous++ {
				if values[1 + previous] == value { return -1 }
			}
			nodes[index].key = i32(value)
			nodes[index].first_child = -1
			nodes[index].next_sibling = -1
		}

		mut root := -1
		for index := 0; index < count; index++ {
			root = meld(root, index, mut nodes)
		}

		mut hash := fnv_offset_basis
		for extraction := 0; extraction < count - 1; extraction++ {
			removed := root
			hash = hash_key(hash, nodes[removed].key)
			mut forest := [max_items]int{}
			mut paired := [max_items]int{}
			mut forest_count := 0
			mut child := nodes[removed].first_child
			nodes[removed].first_child = -1
			for child >= 0 {
				next := nodes[child].next_sibling
				nodes[child].next_sibling = -1
				forest[forest_count] = child
				forest_count++
				child = next
			}
			mut paired_count := 0
			mut index := 0
			for index < forest_count {
				right := if index + 1 < forest_count { forest[index + 1] } else { -1 }
				paired[paired_count] = meld(forest[index], right, mut nodes)
				paired_count++
				index += 2
			}
			mut rebuilt := -1
			for paired_count > 0 {
				paired_count--
				rebuilt = meld(rebuilt, paired[paired_count], mut nodes)
			}
			root = rebuilt
		}
		return i64(hash & mask_63)
	}
}
