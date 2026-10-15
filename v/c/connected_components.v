module connected_components

const max_vertices = 256

fn visit(vertex int, n int, adjacency &bool, mut seen &bool) {
	unsafe { seen[vertex] = true }
	for next in 0 .. n {
		if unsafe { adjacency[vertex * max_vertices + next] && !seen[next] } {
			visit(next, n, adjacency, mut seen)
		}
	}
}

@[export: 'connected_components']
pub fn connected_components(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 1026 { return -1 }
	if unsafe { input[0] < 0 || input[0] > 256 || input[1] < 0 || input[1] > 512 } { return -1 }
	n := int(unsafe { input[0] }); m := int(unsafe { input[1] })
	if int(length) != 2 + 2 * m { return -1 }
	mut adjacency := [max_vertices * max_vertices]bool{}
	for i in 0 .. m {
		u := unsafe { input[2 + 2 * i] }; v := unsafe { input[3 + 2 * i] }
		if u < 1 || u > i64(n) || v < 1 || v > i64(n) { return -1 }
		a := int(u - 1); b := int(v - 1)
		adjacency[a * max_vertices + b] = true; adjacency[b * max_vertices + a] = true
	}
	mut seen := [max_vertices]bool{}
	mut components := i64(0)
	for i in 0 .. n {
		if !seen[i] { visit(i, n, &adjacency[0], mut &seen[0]); components++ }
	}
	return components
}
