module skip_list_unique_key_set

const max_ops = 128
const max_levels = 8
const min_key = i64(-2147483647)
const max_key = i64(2147483646)
struct Node { key i64; value i64; level int; next [max_levels]int }

fn random_level(mut state u32) int {
	mut level := 1
	for level < max_levels {
		state ^= state << 13
		state ^= state >> 17
		state ^= state << 5
		if (state & 1) != 0 { break }
		level++
	}
	return level
}
fn find_update(mut nodes []Node, active int, key i64, mut update []int) int {
	mut current := 0
	for level := active - 1; level >= 0; level-- {
		for nodes[current].next[level] != 0 && nodes[nodes[current].next[level]].key < key { current = nodes[current].next[level] }
		update[level] = current
	}
	return nodes[current].next[0]
}
fn contains(mut nodes []Node, active int, key i64) bool {
	mut update := [max_levels]int{}
	found := find_update(mut nodes, active, key, mut update[..])
	return found != 0 && nodes[found].key == key
}
fn insert(mut nodes []Node, mut next int, mut active int, mut rng u32, key i64) {
	mut update := [max_levels]int{}
	_ = find_update(mut nodes, active, key, mut update[..])
	height := random_level(mut rng)
	if height > active { for level := active; level < height; level++ { update[level] = 0 }; active = height }
	id := next; next++
	nodes[id].key = key; nodes[id].value = key; nodes[id].level = height
	for level in 0 .. height { nodes[id].next[level] = nodes[update[level]].next[level]; nodes[update[level]].next[level] = id }
}
fn erase(mut nodes []Node, active int, key i64) bool {
	mut update := [max_levels]int{}
	found := find_update(mut nodes, active, key, mut update[..])
	if found == 0 || nodes[found].key != key { return false }
	for level in 0 .. active { if nodes[update[level]].next[level] == found { nodes[update[level]].next[level] = nodes[found].next[level] } }
	return true
}

@[export: 'skip_list_unique_key_set']
pub fn skip_list_unique_key_set(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_ops || length != usize(1 + 2 * input[0]) { return -1 }
		ops := int(input[0])
		for i in 0 .. ops { op := input[1 + 2 * i]; key := input[2 + 2 * i]; if op < 0 || op > 2 || key < min_key || key > max_key { return -1 } }
		mut nodes := []Node{len: max_ops + 1}; mut next := 1; mut active := 1; mut rng := u32(0x9e3779b9)
		for i in 0 .. ops {
			op := input[1 + 2 * i]; key := input[2 + 2 * i]
			if op == 0 { if contains(mut nodes, active, key) { return -1 }; insert(mut nodes, mut next, mut active, mut rng, key) }
			else if op == 1 { _ = contains(mut nodes, active, key) }
			else if !erase(mut nodes, active, key) { return -1 }
		}
		mut count := 0; mut id := nodes[0].next[0]
		for id != 0 { count++; id = nodes[id].next[0] }
		needed := count * 8
		if output == nil || capacity < needed { return -2 }
		mut index := 0; id = nodes[0].next[0]
		for id != 0 { bits := u64(nodes[id].value); for byte in 0 .. 8 { output[index * 8 + byte] = u8(bits >> (8 * byte)) }; index++; id = nodes[id].next[0] }
		return i64(needed)
	}
}
