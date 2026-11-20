package elkin_peleg_sparse_spanner

import "core:c"

MAX_N :: 20
MAX_M :: 190
MAX_INPUT :: 383
INF :: 1000

Cluster :: struct { center, radius: int, members: [MAX_N]bool, tree: [MAX_M]bool }
Context :: struct {
	n, m: int,
	adjacent: [MAX_N * MAX_N]bool,
	edge_index: [MAX_N * MAX_N]int,
	distance: [MAX_N * MAX_N]int,
}
Bfs_Result :: struct { parent: [MAX_N]int, distance: [MAX_N]int }

edge_id :: proc(c: ^Context, a, b: int) -> int {
	lo, hi := a, b
	if lo > hi { lo, hi = hi, lo }
	return c.edge_index[lo * MAX_N + hi]
}

bfs :: proc(c: ^Context, source: int, allowed: [MAX_N]bool, restrict: bool) -> Bfs_Result {
	var result: Bfs_Result
	var queue: [MAX_N]int
	head, tail := 0, 1
	queue[0] = source
	for v := 0; v < c.n; v += 1 { result.parent[v] = -1; result.distance[v] = INF }
	result.distance[source] = 0
	for head < tail {
		u := queue[head]; head += 1
		for v := 0; v < c.n; v += 1 {
			if c.adjacent[u * MAX_N + v] && (!restrict || allowed[v]) && result.distance[v] == INF {
				result.parent[v] = u
				result.distance[v] = result.distance[u] + 1
				queue[tail] = v; tail += 1
			}
		}
	}
	return result
}

add_tree :: proc(c: ^Context, allowed: [MAX_N]bool, root: int, chosen: [^]bool) -> int {
	found := bfs(c, root, allowed, true)
	radius := 0
	for v := 0; v < c.n; v += 1 {
		if allowed[v] {
			if found.distance[v] > radius do radius = found.distance[v]
			if v != root { e := edge_id(c, v, found.parent[v]); if e >= 0 do chosen[e] = true }
		}
	}
	return radius
}

set_distance :: proc(c: ^Context, left, right: [MAX_N]bool) -> int {
	best := INF
	for u := 0; u < c.n; u += 1 { if left[u] {
		for v := 0; v < c.n; v += 1 { if right[v] && c.distance[u * MAX_N + v] < best do best = c.distance[u * MAX_N + v] }
	} }
	return best
}

cluster_before :: proc(a, b: Cluster, n: int) -> bool {
	if a.center != b.center do return a.center < b.center
	for v := 0; v < n; v += 1 { if a.members[v] != b.members[v] do return a.members[v] }
	return false
}

add_connector :: proc(c: ^Context, left, right: [MAX_N]bool, chosen: [^]bool) {
	best_distance := INF
	var best_path: [MAX_N]int
	best_length := 0
	for source := 0; source < c.n; source += 1 { if left[source] {
		found := bfs(c, source, [MAX_N]bool{}, false)
		for target := 0; target < c.n; target += 1 {
			if !right[target] || found.distance[target] == INF || found.distance[target] > best_distance do continue
			var reversed: [MAX_N]int
			length := 0
			v := target
			for v >= 0 && length < c.n { reversed[length] = v; length += 1; if v == source do break; v = found.parent[v] }
			if length == 0 || reversed[length - 1] != source do continue
			earlier := best_length == 0 || found.distance[target] < best_distance
			if !earlier && found.distance[target] == best_distance {
				for i := 0; i < length; i += 1 {
					candidate := reversed[length - 1 - i]
					if candidate != best_path[i] { earlier = candidate < best_path[i]; break }
				}
			}
			if earlier {
				best_distance = found.distance[target]
				best_length = length
				for i := 0; i < length; i += 1 { best_path[i] = reversed[length - 1 - i] }
			}
		}
	} }
	for i := 1; i < best_length; i += 1 { e := edge_id(c, best_path[i-1], best_path[i]); if e >= 0 do chosen[e] = true }
}

sigma :: proc(n: int) -> int {
	value := 1
	for value*value*value*value < n do value += 1
	return value
}

supercluster :: proc(c: ^Context, input: [MAX_N]Cluster, count, threshold, delta: int,
	output: [^]Cluster, output_count: ^int, chosen: [^]bool) {
	var active: [MAX_N]bool
	for i := 0; i < count; i += 1 { active[i] = true }
	output_count^ = 0
	for {
		best := -1
		var neighborhoods: [MAX_N * MAX_N]bool
		for candidate := 0; candidate < count; candidate += 1 { if active[candidate] {
			close_count := 0
			for other := 0; other < count; other += 1 {
				if active[other] && set_distance(c, input[candidate].members, input[other].members) <= delta {
					neighborhoods[candidate * MAX_N + other] = true
					close_count += 1
				}
			}
			if close_count >= threshold && (best < 0 || cluster_before(input[candidate], input[best], c.n)) do best = candidate
		} }
		if best < 0 do break
		var merged: Cluster
		merged.center = input[best].center
		for other := 0; other < count; other += 1 { if neighborhoods[best * MAX_N + other] {
			active[other] = false
			for v := 0; v < c.n; v += 1 do merged.members[v] = merged.members[v] || input[other].members[v]
			for e := 0; e < c.m; e += 1 do merged.tree[e] = merged.tree[e] || input[other].tree[e]
			if other != best do add_connector(c, input[best].members, input[other].members, &merged.tree[0])
		} }
		for e := 0; e < c.m; e += 1 do chosen[e] = chosen[e] || merged.tree[e]
		output[output_count^] = merged
		output_count^ += 1
	}
	var remaining: [MAX_N]int
	remain_count := 0
	for i := 0; i < count; i += 1 { if active[i] { remaining[remain_count] = i; remain_count += 1 } }
	for i := 1; i < remain_count; i += 1 {
		key := remaining[i]; position := i
		for position > 0 && cluster_before(input[key], input[remaining[position-1]], c.n) { remaining[position] = remaining[position-1]; position -= 1 }
		remaining[position] = key
	}
	for i := 0; i < remain_count; i += 1 { for j := i+1; j < remain_count; j += 1 {
		if set_distance(c, input[remaining[i]].members, input[remaining[j]].members) <= delta do add_connector(c, input[remaining[i]].members, input[remaining[j]].members, chosen)
	} }
}

construct :: proc(c: ^Context) -> [MAX_M]bool {
	for source := 0; source < c.n; source += 1 {
		found := bfs(c, source, [MAX_N]bool{}, false)
		for v := 0; v < c.n; v += 1 do c.distance[source * MAX_N + v] = found.distance[v]
	}
	var chosen: [MAX_M]bool
	var uncovered: [MAX_N]bool
	for v := 0; v < c.n; v += 1 do uncovered[v] = true
	var ground: [MAX_N]Cluster
	ground_count := 0
	for {
		root := -1
		for v := 0; v < c.n; v += 1 { if uncovered[v] { root = v; break } }
		if root < 0 do break
		var members: [MAX_N]bool
		members[root] = true
		size := 1
		for {
			var shell: [MAX_N]bool
			shell_size := 0
			for v := 0; v < c.n; v += 1 {
				shell[v] = members[v]
				if !shell[v] && uncovered[v] { for u := 0; u < c.n; u += 1 { if members[u] && c.adjacent[u * MAX_N + v] { shell[v] = true; break } } }
				if shell[v] do shell_size += 1
			}
			if shell_size == size || shell_size*shell_size*shell_size*shell_size < c.n*size*size*size*size do break
			for v := 0; v < c.n; v += 1 { if shell[v] && !members[v] { members[v] = true; size += 1 } }
		}
		var shell: [MAX_N]bool
		for v := 0; v < c.n; v += 1 { shell[v] = members[v]; if !shell[v] && uncovered[v] { for u := 0; u < c.n; u += 1 { if members[u] && c.adjacent[u * MAX_N + v] { shell[v] = true; break } } } }
		var cluster: Cluster
		cluster.center = root
		cluster.members = members
		cluster.radius = add_tree(c, members, root, &cluster.tree[0])
		var shell_tree: [MAX_M]bool
		_ = add_tree(c, shell, root, &shell_tree[0])
		for e := 0; e < c.m; e += 1 do chosen[e] = chosen[e] || shell_tree[e]
		ground[ground_count] = cluster
		ground_count += 1
		for v := 0; v < c.n; v += 1 { if members[v] do uncovered[v] = false }
	}
	var level: [MAX_N]Cluster
	level_count := 0
	for i := 0; i < ground_count; i += 1 { if ground[i].radius == 1 { level[level_count] = ground[i]; level_count += 1 } }
	var supers: [MAX_N]Cluster
	var super_count := 0
	supercluster(c, level, level_count, sigma(c.n), 16, &supers[0], &super_count, &chosen[0])
	var final_clusters: [MAX_N]Cluster
	final_count := 0
	for i := 0; i < super_count; i += 1 { final_clusters[final_count] = supers[i]; final_count += 1 }
	for i := 0; i < ground_count; i += 1 { if ground[i].radius == 2 || ground[i].radius == 3 { final_clusters[final_count] = ground[i]; final_count += 1 } }
	for i := 1; i < final_count; i += 1 {
		key := final_clusters[i]; position := i
		for position > 0 && cluster_before(key, final_clusters[position-1], c.n) { final_clusters[position] = final_clusters[position-1]; position -= 1 }
		final_clusters[position] = key
	}
	for i := 0; i < final_count; i += 1 { for j := i+1; j < final_count; j += 1 {
		if set_distance(c, final_clusters[i].members, final_clusters[j].members) <= 128 do add_connector(c, final_clusters[i].members, final_clusters[j].members, &chosen[0])
	} }
	return chosen
}

elkin_peleg_sparse_spanner :: proc "c" (a: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if a == nil || length < 2 || length > MAX_INPUT do return -1
	n64 := a[0]; m64 := a[1]
	if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || length != c.size_t(2 + 2*m64) do return -1
	var cx: Context
	cx.n = int(n64); cx.m = int(m64)
	for i := 0; i < MAX_N * MAX_N; i += 1 { cx.edge_index[i] = -1 }
	for e := 0; e < cx.m; e += 1 {
		u64 := a[2+2*e]; v64 := a[3+2*e]
		if u64 < 0 || v64 <= u64 || v64 >= n64 do return -1
		u := int(u64); v := int(v64)
		if cx.edge_index[u*MAX_N+v] >= 0 do return -1
		cx.edge_index[u*MAX_N+v] = e; cx.edge_index[v*MAX_N+u] = e
		cx.adjacent[u*MAX_N+v] = true; cx.adjacent[v*MAX_N+u] = true
	}
	if output == nil || capacity < c.size_t(cx.m) do return -2
	selected := construct(&cx)
	for e := 0; e < cx.m; e += 1 { if selected[e] { output[e] = 1 } else { output[e] = 0 } }
	return i64(cx.m)
}
