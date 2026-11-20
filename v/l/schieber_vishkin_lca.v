module schieber_vishkin_lca

const max_nodes = 256
const max_queries = 1024
const max_arcs = 510
const max_input = 4 + 2 * (max_nodes - 1) + 2 * max_queries

fn sv_lowbit(value u32) u32 { return value & (u32(0) - value) }

fn sv_highbit(value u32) u32 {
	mut rest := value
	mut bit := u32(0)
	for rest != 0 {
		bit = rest
		rest >>= 1
	}
	return bit
}

@[export: 'schieber_vishkin_lca']
pub fn schieber_vishkin_lca(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > usize(max_input + 1) { return -1 }
		if input[0] < 1 || input[0] > max_nodes { return -1 }
		n := int(input[0])
		if input[1] < 0 || input[1] >= i64(n) || input[2] != i64(n - 1) ||
			input[3] < 0 || input[3] > max_queries { return -1 }
		m := int(input[2])
		q := int(input[3])
		query_offset := 4 + 2 * m
		if length != usize(query_offset + 2 * q) { return -1 }
		root := int(input[1])

		mut head := [max_nodes]int{}
		mut arc_to := [max_arcs]int{}
		mut arc_next := [max_arcs]int{}
		mut parent := [max_nodes]int{}
		mut order := [max_nodes]int{}
		mut stack_node := [max_nodes]int{}
		mut stack_arc := [max_nodes]int{}
		mut preorder := [max_nodes]int{}
		mut inlabel := [max_nodes]u32{}
		mut ascendant := [max_nodes]u32{}
		mut path_parent := [max_nodes]int{}
		mut answers := [max_queries]u8{}
		for node in 0 .. n { head[node] = -1; parent[node] = -2 }
		mut arcs := 0
		for edge in 0 .. m {
			a_value := input[4 + 2 * edge]
			b_value := input[5 + 2 * edge]
			if a_value < 0 || a_value >= i64(n) || b_value < 0 || b_value >= i64(n) || a_value == b_value { return -1 }
			a := int(a_value)
			b := int(b_value)
			arc_to[arcs] = b; arc_next[arcs] = head[a]; head[a] = arcs; arcs++
			arc_to[arcs] = a; arc_next[arcs] = head[b]; head[b] = arcs; arcs++
		}
		for query in 0 .. q {
			for side in 0 .. 2 {
				node := input[query_offset + 2 * query + side]
				if node < 0 || node >= i64(n) { return -1 }
			}
		}

		mut reached := 1
		mut top := 1
		parent[root] = -1; preorder[root] = 1; order[0] = root
		stack_node[0] = root; stack_arc[0] = head[root]
		for top > 0 {
			slot := top - 1
			node := stack_node[slot]
			arc := stack_arc[slot]
			if arc < 0 { top--; continue }
			stack_arc[slot] = arc_next[arc]
			neighbor := arc_to[arc]
			if neighbor == parent[node] { continue }
			if parent[neighbor] != -2 { return -1 }
			parent[neighbor] = node; preorder[neighbor] = reached + 1; order[reached] = neighbor; reached++
			stack_node[top] = neighbor; stack_arc[top] = head[neighbor]; top++
		}
		if reached != n { return -1 }
		if output_capacity < usize(q) || (q > 0 && output == nil) { return -2 }

		for node in 0 .. n { inlabel[node] = u32(preorder[node]) }
		mut i := n
		for i > 1 {
			i--
			node := order[i - 1]
			p := parent[node]
			if sv_lowbit(inlabel[p]) < sv_lowbit(inlabel[node]) { inlabel[p] = inlabel[node] }
		}
		for pos in 0 .. n {
			node := order[pos]
			if parent[node] < 0 {
				ascendant[node] = sv_lowbit(inlabel[node]); path_parent[preorder[node] - 1] = node
			} else {
				p := parent[node]
				ascendant[node] = ascendant[p] | sv_lowbit(inlabel[node])
				path_parent[preorder[node] - 1] = if inlabel[node] != inlabel[p] { p } else { path_parent[preorder[p] - 1] }
			}
		}
		for query in 0 .. q {
			u := int(input[query_offset + 2 * query])
			v := int(input[query_offset + 2 * query + 1])
			lu := sv_lowbit(inlabel[u]); lv := sv_lowbit(inlabel[v])
			mut mask := sv_highbit((inlabel[u] ^ inlabel[v]) | lu | lv) - 1
			j := sv_lowbit(ascendant[u] & ascendant[v] & ~mask)
			if j == 0 { return -1 }
			mut x := u; mut y := v
			if j != lu {
				mask = sv_highbit(ascendant[u] & (j - 1)) - 1
				index := ((preorder[u] & ~int(mask)) | (int(mask) + 1)) - 1
				x = path_parent[index]
			}
			if j != lv {
				mask = sv_highbit(ascendant[v] & (j - 1)) - 1
				index := ((preorder[v] & ~int(mask)) | (int(mask) + 1)) - 1
				y = path_parent[index]
			}
			answer := x
			if preorder[y] < preorder[x] { answer = y }
			answers[query] = u8(answer)
		}
		for query in 0 .. q { output[query] = answers[query] }
		return i64(q)
	}
}
