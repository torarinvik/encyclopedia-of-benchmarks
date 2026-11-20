module dynamic_centroid_active_set_diameter

const max_n = 32
const max_operations = 64
const max_levels = 6
const max_parseable_length = 98

struct Context {
	n int
	adjacency [max_n * max_n]int
	blocked [max_n]int
	subtree_size [max_n]int
	record_count [max_n]int
	record_centroid [max_n * max_levels]int
	record_branch [max_n * max_levels]int
	record_distance [max_n * max_levels]int
	best [max_n * (max_n + 1)]int
	active [max_n]int
}

fn (mut ctx Context) component_size(vertex int, parent int) int {
	mut total := 1
	for neighbor in 0 .. ctx.n {
		if ctx.adjacency[vertex * ctx.n + neighbor] != 0 && neighbor != parent
			&& ctx.blocked[neighbor] == 0 {
			total += ctx.component_size(neighbor, vertex)
		}
	}
	ctx.subtree_size[vertex] = total
	return total
}

fn (ctx &Context) choose_centroid(vertex int, parent int, total int) int {
	for neighbor in 0 .. ctx.n {
		if ctx.adjacency[vertex * ctx.n + neighbor] != 0 && neighbor != parent
			&& ctx.blocked[neighbor] == 0 && ctx.subtree_size[neighbor] > total / 2 {
			return ctx.choose_centroid(neighbor, vertex, total)
		}
	}
	return vertex
}

fn (mut ctx Context) record_component(centroid int, vertex int, parent int,
	distance int, branch int, level int) {
	if level >= max_levels { return }
	index := vertex * max_levels + level
	ctx.record_centroid[index] = centroid
	ctx.record_branch[index] = if vertex == centroid { ctx.n } else { branch }
	ctx.record_distance[index] = distance
	ctx.record_count[vertex] = level + 1
	for neighbor in 0 .. ctx.n {
		if ctx.adjacency[vertex * ctx.n + neighbor] != 0 && neighbor != parent
			&& ctx.blocked[neighbor] == 0 {
			next_branch := if vertex == centroid { neighbor } else { branch }
			ctx.record_component(centroid, neighbor, vertex, distance + 1, next_branch, level)
		}
	}
}

fn (mut ctx Context) build_centroids(entry int, level int) {
	if level >= max_levels { return }
	total := ctx.component_size(entry, -1)
	centroid := ctx.choose_centroid(entry, -1, total)
	ctx.record_component(centroid, centroid, -1, 0, ctx.n, level)
	ctx.blocked[centroid] = 1
	for neighbor in 0 .. ctx.n {
		if ctx.adjacency[centroid * ctx.n + neighbor] != 0 && ctx.blocked[neighbor] == 0 {
			ctx.build_centroids(neighbor, level + 1)
		}
	}
}

fn (mut ctx Context) recompute_branch(centroid int, branch int) {
	bucket := centroid * (ctx.n + 1) + branch
	ctx.best[bucket] = -1
	for vertex in 0 .. ctx.n {
		if ctx.active[vertex] == 0 { continue }
		for record_index in 0 .. ctx.record_count[vertex] {
			index := vertex * max_levels + record_index
			if ctx.record_centroid[index] == centroid && ctx.record_branch[index] == branch
				&& ctx.record_distance[index] > ctx.best[bucket] {
				ctx.best[bucket] = ctx.record_distance[index]
			}
		}
	}
}

fn (ctx &Context) active_diameter() int {
	mut answer := 0
	for centroid in 0 .. ctx.n {
		mut first := -1
		mut second := -1
		for branch in 0 .. ctx.n + 1 {
			distance := ctx.best[centroid * (ctx.n + 1) + branch]
			if distance > first {
				second = first
				first = distance
			} else if distance > second {
				second = distance
			}
		}
		if second >= 0 && first + second > answer { answer = first + second }
	}
	return answer
}

@[export: 'dynamic_centroid_active_set_diameter']
pub fn dynamic_centroid_active_set_diameter(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_parseable_length) { return -1 }
	n_value := unsafe { input[0] }
	q_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_n || q_value < 0 || q_value > max_operations { return -1 }
	n := int(n_value)
	q := int(q_value)
	if length != usize(n + 1 + q) { return -1 }

	mut ctx := Context{n: n}
	for vertex in 1 .. n {
		parent_value := unsafe { input[vertex + 1] }
		if parent_value < 0 || parent_value >= i64(vertex) { return -1 }
		parent := int(parent_value)
		ctx.adjacency[parent * n + vertex] = 1
		ctx.adjacency[vertex * n + parent] = 1
	}
	for offset in 0 .. q {
		operation := unsafe { input[n + 1 + offset] }
		if operation != -1 && (operation < 0 || operation >= i64(n)) { return -1 }
	}
	ctx.build_centroids(0, 0)
	for centroid in 0 .. n {
		for branch in 0 .. n + 1 { ctx.best[centroid * (n + 1) + branch] = -1 }
	}

	mut checksum := i64(0)
	mut query_number := i64(0)
	for offset in 0 .. q {
		operation := unsafe { input[n + 1 + offset] }
		if operation == -1 {
			query_number++
			checksum += query_number * i64(ctx.active_diameter() + 1)
			continue
		}
		vertex := int(operation)
		ctx.active[vertex] = if ctx.active[vertex] == 0 { 1 } else { 0 }
		for record_index in 0 .. ctx.record_count[vertex] {
			index := vertex * max_levels + record_index
			centroid := ctx.record_centroid[index]
			branch := ctx.record_branch[index]
			distance := ctx.record_distance[index]
			bucket := centroid * (n + 1) + branch
			if ctx.active[vertex] != 0 {
				if distance > ctx.best[bucket] { ctx.best[bucket] = distance }
			} else if ctx.best[bucket] == distance {
				ctx.recompute_branch(centroid, branch)
			}
		}
	}
	return checksum
}
