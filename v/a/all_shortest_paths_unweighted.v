module all_shortest_paths_unweighted

const max_vertices = 16
const max_edges = 64
const max_input = 133
const max_paths = 162
const max_output = 1296

struct Search {
	n int
	target int
	predecessor [256]bool
	useful [16]bool
	path [16]u8
	output [1296]u8
	used int
	count int
	overflow bool
}

fn (mut s Search) visit(u int, depth int) {
	if s.overflow { return }
	s.path[depth] = u8(u)
	if u == s.target {
		if s.count >= max_paths || s.used + depth + 2 > max_output { s.overflow = true; return }
		for i in 0 .. depth + 1 { s.output[s.used] = s.path[i]; s.used++ }
		s.output[s.used] = 0xff; s.used++; s.count++
		return
	}
	for v in 0 .. s.n {
		if s.useful[v] && s.predecessor[v * max_vertices + u] { s.visit(v, depth + 1) }
	}
}

@[export: 'all_shortest_paths_unweighted']
pub fn all_shortest_paths_unweighted(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input { return -1 }
	if unsafe { input[0] < 1 || input[0] > max_vertices || input[1] < 0 || input[1] > max_edges } { return -1 }
	n := int(unsafe { input[0] }); m := int(unsafe { input[1] })
	source_value := unsafe { input[2] }; target_value := unsafe { input[3] }
	if source_value < 0 || source_value >= i64(n) || target_value < 0 || target_value >= i64(n) || length != usize(4 + 2 * m) { return -1 }
	source := int(source_value); target := int(target_value)
	mut adjacent := [256]bool{}
	for e in 0 .. m {
		raw_u := unsafe { input[4 + 2 * e] }; raw_v := unsafe { input[5 + 2 * e] }
		if raw_u < 0 || raw_u >= i64(n) || raw_v < 0 || raw_v >= i64(n) || raw_u == raw_v { return -1 }
		u := int(raw_u); v := int(raw_v)
		if adjacent[u * max_vertices + v] { return -1 }
		adjacent[u * max_vertices + v] = true; adjacent[v * max_vertices + u] = true
	}
	mut distance := [16]int{}
	mut queue := [16]int{}
	mut predecessor := [256]bool{}
	for v in 0 .. n { distance[v] = -1 }
	mut head := 0; mut tail := 0
	distance[source] = 0; queue[tail] = source; tail++
	for head < tail {
		u := queue[head]; head++
		for v in 0 .. n {
			if !adjacent[u * max_vertices + v] { continue }
			if distance[v] < 0 { distance[v] = distance[u] + 1; queue[tail] = v; tail++ }
			if distance[v] == distance[u] + 1 { predecessor[v * max_vertices + u] = true }
		}
	}
	mut useful := [16]bool{}
	if distance[target] >= 0 {
		mut stack := [16]int{}
		mut size := 0
		useful[target] = true; stack[size] = target; size++
		for size > 0 {
			size--; v := stack[size]
			for u in 0 .. n {
				if predecessor[v * max_vertices + u] && !useful[u] { useful[u] = true; stack[size] = u; size++ }
			}
		}
	}
	mut s := Search{n: n, target: target, predecessor: predecessor, useful: useful}
	if distance[target] >= 0 { s.visit(source, 0) }
	if s.overflow { return -2 }
	if unsafe { output == nil } || capacity < usize(s.used) { return -2 }
	unsafe { for i in 0 .. s.used { output[i] = s.output[i] } }
	i64(s.count)
}
