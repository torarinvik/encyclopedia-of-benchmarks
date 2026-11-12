module lengauer_tarjan_dominator_tree

const max_v = 63
const max_e = 2047
const max_input = usize(4097)

fn lt_eval(vertex int, mut ancestor &int, mut label &int, semi &int, mut path &int) int {
	unsafe {
		if ancestor[vertex] == 0 { return vertex }
		mut used := 0
		mut current := vertex
		for ancestor[ancestor[current]] != 0 { path[used] = current; used++; current = ancestor[current] }
		for used > 0 {
			used--
			current = path[used]
			p := ancestor[current]
			if semi[label[p]] < semi[label[current]] { label[current] = label[p] }
			ancestor[current] = ancestor[p]
		}
		return label[vertex]
	}
}

@[export: 'lengauer_tarjan_dominator_tree']
pub fn lengauer_tarjan_dominator_tree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input { return -1 }
	unsafe {
		nv, root_value, me := input[0], input[1], input[2]
		if nv < 1 || nv > max_v || root_value < 0 || root_value >= nv || me < 0 || me > max_e { return -1 }
		n, root, m := int(nv), int(root_value), int(me)
		if int(length) != 3 + 2 * m { return -1 }

		mut outmask := [max_v]u64{}
		mut out_head := [max_v]int{init: -1}
		mut edge_source := [max_e]int{}
		mut edge_target := [max_e]int{}
		mut out_next := [max_e]int{init: -1}
		mut pred_head := [max_v + 1]int{init: -1}
		mut pred_next := [max_e]int{init: -1}
		mut dfs_number := [max_v]int{}
		mut vertex_at := [max_v + 1]int{}
		mut parent := [max_v + 1]int{}
		mut semi := [max_v + 1]int{}
		mut ancestor := [max_v + 1]int{}
		mut label := [max_v + 1]int{}
		mut immediate := [max_v + 1]int{}
		mut bucket_head := [max_v + 1]int{init: -1}
		mut bucket_next := [max_v + 1]int{}
		mut node_stack := [max_v]int{}
		mut edge_stack := [max_v]int{init: -1}
		mut eval_path := [max_v + 1]int{}
		mut staged := [max_v]u8{}
		mut edge_count := 0
		for i in 0 .. m {
			sv, tv := input[3 + 2 * i], input[4 + 2 * i]
			if sv < 0 || sv >= nv || tv < 0 || tv >= nv { return -1 }
			s, t := int(sv), int(tv)
			bit := u64(1) << t
			if outmask[s] & bit == 0 {
				outmask[s] |= bit
				edge_source[edge_count] = s
				edge_target[edge_count] = t
				out_next[edge_count] = out_head[s]
				out_head[s] = edge_count
				edge_count++
			}
		}

		mut dfs_count, mut top := 1, 1
		dfs_number[root] = 1
		vertex_at[1] = root
		node_stack[0] = root
		edge_stack[0] = out_head[root]
		for top > 0 {
			frame := top - 1
			current, edge := node_stack[frame], edge_stack[frame]
			if edge == -1 { top--; continue }
			edge_stack[frame] = out_next[edge]
			target := edge_target[edge]
			if dfs_number[target] == 0 {
				dfs_count++
				dfs_number[target] = dfs_count
				vertex_at[dfs_count] = target
				parent[dfs_count] = dfs_number[current]
				node_stack[top] = target
				edge_stack[top] = out_head[target]
				top++
			}
		}
		for edge in 0 .. edge_count {
			source_number, target_number := dfs_number[edge_source[edge]], dfs_number[edge_target[edge]]
			if source_number != 0 && target_number != 0 { pred_next[edge] = pred_head[target_number]; pred_head[target_number] = edge }
		}
		for vertex in 1 .. dfs_count + 1 { semi[vertex] = vertex; label[vertex] = vertex }
		for w := dfs_count; w >= 2; w-- {
			for edge := pred_head[w]; edge != -1; edge = pred_next[edge] {
				predecessor := dfs_number[edge_source[edge]]
				representative := lt_eval(predecessor, &ancestor[0], &label[0], &semi[0], &eval_path[0])
				if semi[representative] < semi[w] { semi[w] = semi[representative] }
			}
			bucket_next[w] = bucket_head[semi[w]]
			bucket_head[semi[w]] = w
			ancestor[w] = parent[w]
			owner := parent[w]
			member := bucket_head[owner]
			bucket_head[owner] = -1
			for member != -1 {
				next := bucket_next[member]
				representative := lt_eval(member, &ancestor[0], &label[0], &semi[0], &eval_path[0])
				if semi[representative] < semi[member] { immediate[member] = representative } else { immediate[member] = owner }
				member = next
			}
		}
		for w in 2 .. dfs_count + 1 { if immediate[w] != semi[w] { immediate[w] = immediate[immediate[w]] } }
		immediate[1] = 1
		for vertex in 0 .. n {
			number := dfs_number[vertex]
			if number == 0 { staged[vertex] = 255 } else { staged[vertex] = u8(vertex_at[immediate[number]]) }
		}
		if output == nil || capacity < usize(n) { return -2 }
		for vertex in 0 .. n { output[vertex] = staged[vertex] }
		return i64(n)
	}
}
