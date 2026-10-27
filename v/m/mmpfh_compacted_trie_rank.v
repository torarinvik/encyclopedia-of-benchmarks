struct TrieNode { bit int left int right int key u32 low u32 high u32 leaves int }
const max_k = 16
const max_q = 16
const max_nodes = 31
const max_out = 174

fn mmpfh_compacted_build(lo int, hi int, width int, keys []u32, mut nodes []TrieNode, mut used &int) int {
	id := used; used++
	if hi - lo == 1 { nodes[id] = TrieNode{-1, -1, -1, keys[lo], keys[lo], keys[lo], 1}; return id }
	diff := keys[lo] ^ keys[hi - 1]
	mut bit := width - 1
	for ((diff >> u32(bit)) & 1) == 0 { bit-- }
	mut split := lo
	for split < hi && ((keys[split] >> u32(bit)) & 1) == 0 { split++ }
	nodes[id].bit = width - 1 - bit
	nodes[id].low = keys[lo]; nodes[id].high = keys[hi - 1]
	nodes[id].left = mmpfh_compacted_build(lo, split, width, keys, mut nodes, mut used)
	nodes[id].right = mmpfh_compacted_build(split, hi, width, keys, mut nodes, mut used)
	nodes[id].leaves = nodes[nodes[id].left].leaves + nodes[nodes[id].right].leaves
	return id
}
fn mmpfh_compacted_rank(query u32, width int, nodes []TrieNode) int {
	mut id := 0; mut rank := 0
	for true {
		if query < nodes[id].low { return rank }
		if query > nodes[id].high { return rank + nodes[id].leaves }
		if nodes[id].bit < 0 { return rank }
		shift := width - 1 - nodes[id].bit
		if ((query >> u32(shift)) & 1) != 0 { rank += nodes[nodes[id].left].leaves; id = nodes[id].right } else { id = nodes[id].left }
	}
}
fn mmpfh_compacted_put(mut out &u8, position int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { out[position + b] = u8((bits >> u64(b * 8)) & 255) } }
}

@[export: 'mmpfh_compacted_trie_rank']
pub fn mmpfh_compacted_trie_rank(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 35 { return -1 }
		w0 := input[0]; d0 := input[1]; q0 := input[2]
		if w0 < 1 || w0 > 16 || d0 < 1 || d0 > 16 || q0 < 1 || q0 > 16 || length != usize(3 + d0 + q0) { return -1 }
		limit := u32(1) << u32(w0)
		mut keys := []u32{len: int(d0), init: 0}
		for i in 0 .. int(d0) { x := input[3 + i]; if x < 0 || u64(x) >= u64(limit) || (i > 0 && x <= input[2 + i]) { return -1 }; keys[i] = u32(x) }
		for i in 0 .. int(q0) { x := input[3 + int(d0) + i]; if x < 0 || u64(x) >= u64(limit) { return -1 } }
		mut nodes := []TrieNode{len: max_nodes, init: TrieNode{-1, -1, -1, 0, 0, 0, 0}}
		mut used := 0
		mmpfh_compacted_build(0, int(d0), int(w0), keys, mut nodes, mut used)
		mut staged := []i64{len: max_out, init: 0}
		mut pos := 0; staged[pos] = d0; pos++; staged[pos] = i64(used); pos++; staged[pos] = q0; pos++
		for i in 0 .. used { nd := nodes[i]; staged[pos] = i64(nd.bit); pos++; staged[pos] = i64(nd.left); pos++; staged[pos] = i64(nd.right); pos++; staged[pos] = i64(nd.low); pos++; staged[pos] = i64(nd.high); pos++ }
		for i in 0 .. int(q0) { staged[pos] = i64(mmpfh_compacted_rank(u32(input[3 + int(d0) + i]), int(w0), nodes)); pos++ }
		required := pos * 8
		if output == nil || capacity < usize(required) { return -2 }
		for i in 0 .. pos { mmpfh_compacted_put(mut output, i * 8, staged[i]) }
		return i64(required)
	}
}
