module reverse_delete_mst

const max_n = 8
const max_m = 20
const max_input = 63

struct Edge {
	u i32
	v i32
	weight i32
}

fn graph_connected(n int, m int, edges [max_m]Edge, active u64) bool {
	mut seen := [max_n]bool{}
	mut queue := [max_n]int{}
	mut head := 0
	mut tail := 1
	seen[0] = true
	queue[0] = 0
	for head < tail {
		vertex := queue[head]
		head++
		for id in 0 .. m {
			if ((active >> id) & 1) == 0 { continue }
			mut neighbor := -1
			if int(edges[id].u) == vertex { neighbor = int(edges[id].v) }
			else if int(edges[id].v) == vertex { neighbor = int(edges[id].u) }
			if neighbor >= 0 && !seen[neighbor] {
				seen[neighbor] = true
				queue[tail] = neighbor
				tail++
			}
		}
	}
	for vertex in 0 .. n { if !seen[vertex] { return false } }
	return true
}

fn store_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'reverse_delete_mst']
pub fn reverse_delete_mst(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > max_input { return -1 }
	n_word := input[0]
	m_word := input[1]
	if n_word < 2 || n_word > max_n || m_word < n_word - 1 || m_word > max_m { return -1 }
	n := int(n_word)
	m := int(m_word)
	if length != usize(2 + 3 * m) { return -1 }
	mut edges := [max_m]Edge{}
	mut order := [max_m]int{}
	for id in 0 .. m {
		u := input[2 + 3 * id]
		v := input[3 + 3 * id]
		weight := input[4 + 3 * id]
		if u < 0 || u >= n_word || v < 0 || v >= n_word || u == v || weight < 0 || weight > 1000 { return -1 }
		edges[id] = Edge{u: i32(u), v: i32(v), weight: i32(weight)}
		order[id] = id
		low := if u < v { u } else { v }
		high := if u < v { v } else { u }
		for prior in 0 .. id {
			plow := if edges[prior].u < edges[prior].v { edges[prior].u } else { edges[prior].v }
			phigh := if edges[prior].u < edges[prior].v { edges[prior].v } else { edges[prior].u }
			if low == i64(plow) && high == i64(phigh) { return -1 }
		}
	}
	for i in 1 .. m {
		item := order[i]
		mut j := i
		for j > 0 && (edges[order[j - 1]].weight < edges[item].weight ||
			(edges[order[j - 1]].weight == edges[item].weight && order[j - 1] < item)) {
			order[j] = order[j - 1]
			j--
		}
		order[j] = item
	}
	mut active := (u64(1) << m) - 1
	if !graph_connected(n, m, edges, active) { return -1 }
	for position in 0 .. m {
		candidate := active & ~(u64(1) << order[position])
		if graph_connected(n, m, edges, candidate) { active = candidate }
	}
	mut total_weight := i64(0)
	for id in 0 .. m { if ((active >> id) & 1) != 0 { total_weight += i64(edges[id].weight) } }
	if output == nil || capacity < 16 { return -2 }
	store_i64_le(mut output, 0, i64(active))
	store_i64_le(mut output, 8, total_weight)
	return 16
}
