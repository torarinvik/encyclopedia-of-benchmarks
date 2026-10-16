module autocomplete_using_trie

const max_words = 32
const max_len = 16
const max_queries = 16
const max_nodes = 513
const max_output_words = 8721

struct TrieNode {
	mut:
	child [26]int
	terminal bool
}

fn collect(nodes []TrieNode, node int, mut path []int, depth int, mut values []i64) int {
	mut count := 0
	if nodes[node].terminal {
		values << i64(depth)
		for i in 0 .. depth { values << i64(97 + path[i]) }
		count++
	}
	for c in 0 .. 26 {
		child := nodes[node].child[c]
		if child >= 0 {
			path[depth] = c
			count += collect(nodes, child, mut path, depth + 1, mut values)
		}
	}
	return count
}
fn put_i64(output &u8, index int, value i64) {
	bits := u64(value)
	unsafe { for b in 0 .. 8 { output[index*8+b] = u8((bits >> u64(8*b)) & 255) } }
}

@[export: 'autocomplete_using_trie']
pub fn autocomplete_using_trie(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_words { return -1 }
		mut nodes := []TrieNode{len: max_nodes}
		for i in 0 .. max_nodes { for c in 0 .. 26 { nodes[i].child[c] = -1 } }
		mut node_count := 1; mut pos := 1
		for _ in 0 .. int(input[0]) {
			if pos >= int(length) { return -1 }
			word_len := input[pos]; pos++
			if word_len < 1 || word_len > max_len || pos + int(word_len) > int(length) { return -1 }
			mut at := 0
			for _ in 0 .. int(word_len) {
				ch := input[pos]; pos++
				if ch < 97 || ch > 122 { return -1 }
				cidx := int(ch - 97)
				if nodes[at].child[cidx] < 0 { if node_count >= max_nodes { return -1 }; for c in 0 .. 26 { nodes[node_count].child[c] = -1 }; nodes[at].child[cidx] = node_count; node_count++ }
				at = nodes[at].child[cidx]
			}
			nodes[at].terminal = true
		}
		if pos >= int(length) { return -1 }
		qv := input[pos]; pos++
		if qv < 0 || qv > max_queries { return -1 }
		q := int(qv); mut qp := [max_queries]int{}; mut ql := [max_queries]int{}
		for i in 0 .. q {
			if pos >= int(length) { return -1 }
			lv := input[pos]; pos++
			if lv < 0 || lv > max_len || pos + int(lv) > int(length) { return -1 }
			qp[i], ql[i] = pos, int(lv)
			for j in 0 .. ql[i] { if input[pos+j] < 97 || input[pos+j] > 122 { return -1 } }
			pos += ql[i]
		}
		if pos != int(length) { return -1 }
		mut values := []i64{}
		values << i64(q)
		for qi in 0 .. q {
			mut at := 0; mut path := [max_len]int{}; mut found := true
			for j in 0 .. ql[qi] { cidx := int(input[qp[qi]+j]-97); path[j] = cidx; child := nodes[at].child[cidx]; if child < 0 { found = false; break }; at = child }
			cp := values.len
			values << 0
			mut count := 0
			if found { count = collect(nodes, at, mut path[..], ql[qi], mut values) }
			values[cp] = i64(count)
		}
		needed := values.len * 8
		if output == nil || capacity < usize(needed) { return -2 }
		for i in 0 .. values.len { put_i64(output,i,values[i]) }
		return i64(needed)
	}
}
