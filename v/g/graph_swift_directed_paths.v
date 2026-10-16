module graph_swift_directed_paths

const n_max = 32
const m_max = 256
const q_max = 64

@[export: 'graph_swift_directed_paths']
pub fn graph_swift_directed_paths(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 { return -1 }
	unsafe {
		n64, m64 := input[0], input[1]
		if n64 < 1 || n64 > n_max || m64 < 0 || m64 > m_max { return -1 }
		qp := usize(2 + 2*m64)
		if length < qp + 1 { return -1 }
		q64 := input[qp]
		if q64 < 1 || q64 > q_max || length != qp + 1 + 3*usize(q64) { return -1 }
		n, m, q := int(n64), int(m64), int(q64)
		mut adj := [n_max][m_max]int{}
		mut degree := [n_max]int{}
		for i in 0 .. m {
			u64, v64 := input[2+2*i], input[3+2*i]
			if u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64 { return -1 }
			u := int(u64); adj[u][degree[u]] = int(v64); degree[u]++
		}
		mut modes := [q_max]int{}; mut starts := [q_max]int{}; mut dests := [q_max]int{}
		for i in 0 .. q {
			p := qp + 1 + 3*i; mode, start, dest := input[p], input[p+1], input[p+2]
			if mode < 0 || mode > 1 || start < 0 || start >= n64 || dest < 0 || dest >= n64 { return -1 }
			modes[i], starts[i], dests[i] = int(mode), int(start), int(dest)
		}
		mut lens := [q_max]int{}; mut paths := [q_max][n_max]int{}
		mut words := 0
		for qi in 0 .. q {
			start, dest := starts[qi], dests[qi]; lens[qi] = -1
			if modes[qi] == 0 {
				mut stack := [n_max + 1]int{}; mut next_edge := [n_max + 1]int{}; mut visited := [n_max]bool{}; mut depth := 0; stack[0] = start; visited[start] = true
				for {
					current := stack[depth]
					if current == dest { lens[qi] = depth; for j in 0 .. depth { paths[qi][j] = stack[j+1] }; break }
					if next_edge[depth] < degree[current] { next := adj[current][next_edge[depth]]; next_edge[depth]++; if !visited[next] { visited[next] = true; depth++; stack[depth] = next; next_edge[depth] = 0 } }
					else if depth == 0 { break }
					else { depth-- }
				}
			} else {
				mut parent := [n_max]int{}; for i in 0 .. n_max { parent[i] = -1 }
				mut queue := [n_max]int{}; mut head := 0; mut tail := 0; parent[start] = start; queue[tail] = start; tail++
				for head < tail { current := queue[head]; head++; if current == dest { break }; for j in 0 .. degree[current] { next := adj[current][j]; if parent[next] == -1 { parent[next] = current; queue[tail] = next; tail++ } } }
				if parent[dest] != -1 { mut reverse := [n_max]int{}; mut count := 0; mut current := dest; for current != start { reverse[count] = current; count++; current = parent[current] }; lens[qi] = count; for j in 0 .. count { paths[qi][j] = reverse[count-1-j] } }
			}
			words++; if lens[qi] > 0 { words += lens[qi] }
		}
		needed := words * 8
		if output == nil || capacity < usize(needed) { return -2 }
		mut word := 0
		for qi in 0 .. q { unsafe { put_i64(output, word, i64(lens[qi])) }; word++; for j in 0 .. lens[qi] { unsafe { put_i64(output, word, i64(paths[qi][j])) }; word++ } }
		return i64(needed)
	}
}
fn put_i64(output &u8, word int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[word * 8 + byte] = u8((bits >> u64(byte * 8)) & 255) } }
}
