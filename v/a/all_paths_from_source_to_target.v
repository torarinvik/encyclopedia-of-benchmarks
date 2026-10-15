const max_v = 8
const max_e = 24
const max_paths = 1000
const max_output = 72008

struct Search {
	adj [192]int
	degree [8]int
	visited [8]bool
	path [8]int
	target int
	count int
	out [max_output]u8
	at int
	overflow bool
}
fn put_i64(mut output []u8, at int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { output[at+b] = u8((bits >> (8*b)) & 255) }
}
fn dfs(mut s Search, current int, depth int) {
	if s.overflow { return }
	if current == s.target {
		if s.count >= max_paths { s.overflow = true; return }
		put_i64(mut s.out[..], s.at, i64(depth)); s.at += 8
		for i in 0 .. depth { put_i64(mut s.out[..], s.at, i64(s.path[i])); s.at += 8 }
		s.count++; return
	}
	s.visited[current] = true
	for i in 0 .. s.degree[current] {
		if s.overflow { break }
		next := s.adj[current*max_e+i]
		if !s.visited[next] { s.path[depth] = next; dfs(mut s, next, depth+1) }
	}
	s.visited[current] = false
}

@[export: 'all_paths_from_source_to_target']
pub fn all_paths_from_source_to_target(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { values == nil } || length < 4 || length > 52 { return -1 }
	if unsafe { values[0] < 1 || values[0] > max_v || values[1] < 0 || values[1] > max_e } { return -1 }
	nv := int(unsafe { values[0] }); ne := int(unsafe { values[1] }); source := unsafe { values[2] }; target := unsafe { values[3] }
	if source < 0 || source >= i64(nv) || target < 0 || target >= i64(nv) || length != usize(4+2*ne) { return -1 }
	mut s := Search{target: int(target), at: 8}
	for e in 0 .. ne {
		a := unsafe { values[4+2*e] }; b := unsafe { values[5+2*e] }
		if a < 0 || a >= i64(nv) || b < 0 || b >= i64(nv) { return -1 }
		s.adj[int(a)*max_e+s.degree[int(a)]] = int(b); s.degree[int(a)]++
	}
	s.path[0] = int(source); dfs(mut s, int(source), 1)
	if s.overflow { return -2 }
	put_i64(mut s.out[..], 0, i64(s.count))
	if unsafe { output == nil } || capacity < usize(s.at) { return -2 }
	for i in 0 .. s.at { unsafe { output[i] = s.out[i] } }
	i64(s.at)
}
