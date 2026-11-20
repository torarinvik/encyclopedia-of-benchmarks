module canonical_order_schnyder_realizer

const max_n = 8
const max_input = 49
const max_darts = 48

struct Embedding {
	n int
	u int
	v int
	w int
	degree []int
	rotation []int
	adjacent []bool
}

fn next_active(g &Embedding, active []bool, source int, target int) int {
	mut source_position := -1
	mut remaining := 0
	for index in 0 .. g.degree[target] {
		neighbor := g.rotation[target * max_n + index]
		if !active[neighbor] { continue }
		remaining++
		if neighbor == source { source_position = index }
	}
	if remaining < 2 || source_position < 0 { return -1 }
	for step in 1 .. g.degree[target] + 1 {
		neighbor := g.rotation[target * max_n + (source_position + step) % g.degree[target]]
		if active[neighbor] { return neighbor }
	}
	return -1
}

fn face_cycle(g &Embedding, active []bool, first int, second int, mut cycle []int) int {
	mut seen := []bool{len: max_n * max_n}
	mut source := first
	mut target := second
	mut length := 0
	for _ in 0 .. max_darts {
		if source < 0 || source >= g.n || target < 0 || target >= g.n || !active[source] || !active[target] ||
			!g.adjacent[source * max_n + target] || seen[source * max_n + target] { return -1 }
		seen[source * max_n + target] = true
		cycle[length] = source
		length++
		following := next_active(g, active, source, target)
		if following < 0 { return -1 }
		source = target
		target = following
		if source == first && target == second { return length }
	}
	return -1
}

fn parse_embedding(input &i64, length usize) ?Embedding {
	if length < 4 || length > max_input { return none }
	n_raw := unsafe { input[0] }
	if n_raw < 3 || n_raw > max_n { return none }
	n := int(n_raw)
	u_raw := unsafe { input[1] }
	v_raw := unsafe { input[2] }
	w_raw := unsafe { input[3] }
	if u_raw < 0 || u_raw >= n_raw || v_raw < 0 || v_raw >= n_raw || w_raw < 0 || w_raw >= n_raw ||
		u_raw == v_raw || u_raw == w_raw || v_raw == w_raw { return none }
	mut g := Embedding{n: n, u: int(u_raw), v: int(v_raw), w: int(w_raw), degree: []int{len: max_n},
		rotation: []int{len: max_n * max_n}, adjacent: []bool{len: max_n * max_n}}
	mut offset := usize(4)
	mut degree_sum := 0
	for vertex in 0 .. n {
		if offset >= length { return none }
		degree_raw := unsafe { input[offset] }
		offset++
		if degree_raw < 2 || degree_raw >= n_raw || offset + usize(degree_raw) > length { return none }
		degree := int(degree_raw)
		g.degree[vertex] = degree
		degree_sum += degree
		mut row_seen := []bool{len: max_n}
		for rank in 0 .. degree {
			raw := unsafe { input[offset] }
			offset++
			if raw < 0 || raw >= n_raw || raw == i64(vertex) { return none }
			neighbor := int(raw)
			if row_seen[neighbor] { return none }
			row_seen[neighbor] = true
			g.rotation[vertex * max_n + rank] = neighbor
			g.adjacent[vertex * max_n + neighbor] = true
		}
	}
	if offset != length || degree_sum != 6 * n - 12 { return none }
	mut edge_count := 0
	for a in 0 .. n {
		for b in 0 .. n {
			if g.adjacent[a * max_n + b] != g.adjacent[b * max_n + a] { return none }
			if a < b && g.adjacent[a * max_n + b] { edge_count++ }
		}
	}
	if edge_count != 3 * n - 6 { return none }
	mut reached := []bool{len: max_n}
	mut stack := []int{len: max_n}
	mut stack_size := 1
	mut reached_count := 0
	reached[0] = true
	for stack_size > 0 {
		stack_size--
		vertex := stack[stack_size]
		reached_count++
		for neighbor in 0 .. n {
			if g.adjacent[vertex * max_n + neighbor] && !reached[neighbor] {
				reached[neighbor] = true
				stack[stack_size] = neighbor
				stack_size++
			}
		}
	}
	if reached_count != n { return none }
	mut active := []bool{len: max_n}
	for i in 0 .. n { active[i] = true }
	mut seen_dart := []bool{len: max_n * max_n}
	mut face_count := 0
	mut visited_darts := 0
	for source in 0 .. n {
		for target in 0 .. n {
			if !g.adjacent[source * max_n + target] || seen_dart[source * max_n + target] { continue }
			mut cycle := []int{len: max_darts}
			face_length := face_cycle(&g, active, source, target, mut cycle)
			if face_length != 3 { return none }
			face_count++
			for i in 0 .. face_length {
				a := cycle[i]
				b := cycle[(i + 1) % face_length]
				if seen_dart[a * max_n + b] { return none }
				seen_dart[a * max_n + b] = true
				visited_darts++
			}
		}
	}
	if face_count != 2 * n - 4 || visited_darts != 6 * n - 12 { return none }
	mut outer := []int{len: max_darts}
	outer_length := face_cycle(&g, active, g.u, g.v, mut outer)
	if outer_length != 3 || outer[0] != g.u || outer[1] != g.v || outer[2] != g.w { return none }
	return g
}

fn boundary_path(g &Embedding, active []bool, mut path []int) int {
	mut cycle := []int{len: max_darts}
	length := face_cycle(g, active, g.u, g.v, mut cycle)
	if length < 3 { return -1 }
	mut count := 1
	path[0] = g.u
	for i := length - 1; i >= 2; i-- {
		path[count] = cycle[i]
		count++
	}
	path[count] = g.v
	return count + 1
}

fn peel_choice(g &Embedding, path []int, length int) int {
	mut chord := []bool{len: max_n * max_n}
	mut chord_count := 0
	for left in 0 .. length {
		for right in left + 2 .. length {
			if left == 0 && right == length - 1 { continue }
			if g.adjacent[path[left] * max_n + path[right]] {
				chord[left * max_n + right] = true
				chord_count++
			}
		}
	}
	mut eligible := []bool{len: max_n}
	if chord_count == 0 {
		for i in 1 .. length - 1 { eligible[path[i]] = true }
	} else {
		for left in 0 .. length {
			for right in left + 2 .. length {
				if !chord[left * max_n + right] { continue }
				mut minimal := true
				for a in left .. right {
					for b in a + 2 .. right + 1 {
						if chord[a * max_n + b] && (a != left || b != right) { minimal = false }
					}
				}
				if minimal { for i in left + 1 .. right { eligible[path[i]] = true } }
			}
		}
	}
	for vertex in 0 .. g.n { if eligible[vertex] { return vertex } }
	return -1
}

fn peel_contains(g &Embedding, path []int, length int, candidate int) bool {
	mut chord := []bool{len: max_n * max_n}
	mut chord_count := 0
	for left in 0 .. length {
		for right in left + 2 .. length {
			if left == 0 && right == length - 1 { continue }
			if g.adjacent[path[left] * max_n + path[right]] {
				chord[left * max_n + right] = true
				chord_count++
			}
		}
	}
	mut eligible := []bool{len: max_n}
	if chord_count == 0 {
		for i in 1 .. length - 1 { eligible[path[i]] = true }
	} else {
		for left in 0 .. length {
			for right in left + 2 .. length {
				if !chord[left * max_n + right] { continue }
				mut minimal := true
				for a in left .. right {
					for b in a + 2 .. right + 1 {
						if chord[a * max_n + b] && (a != left || b != right) { minimal = false }
					}
				}
				if minimal { for i in left + 1 .. right { eligible[path[i]] = true } }
			}
		}
	}
	return candidate >= 0 && candidate < g.n && eligible[candidate]
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'canonical_order_schnyder_realizer']
pub fn canonical_order_schnyder_realizer(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 6 || length > 57 { return -1 }
	if input[0] < 3 || input[0] > max_n { return -1 }
	n := int(input[0])
	if length < usize(n + 4) { return -1 }
	graph_length := length - usize(n)
	parsed := parse_embedding(input, graph_length)
	if parsed == none { return -1 }
	g := parsed or { return -1 }
	if g.n != n { return -1 }
	mut order := []int{len: max_n}
	mut order_seen := []bool{len: max_n}
	for i in 0 .. n {
		raw := input[graph_length + usize(i)]
		if raw < 0 || raw >= i64(n) || order_seen[int(raw)] { return -1 }
		order[i] = int(raw)
		order_seen[order[i]] = true
	}
	if order[0] != g.u || order[1] != g.v || order[n - 1] != g.w { return -1 }
	mut active := []bool{len: max_n}
	for i in 0 .. n { active[i] = true }
	mut path := []int{len: max_n}
	if n > 3 {
		active[g.w] = false
		mut path_length := boundary_path(&g, active, mut path)
		if path_length < 3 { return -1 }
		mut reverse_index := n - 2
		for reverse_index >= 3 {
			candidate := order[reverse_index]
			if candidate == g.u || candidate == g.v || !active[candidate] || !peel_contains(&g, path, path_length, candidate) { return -1 }
			active[candidate] = false
			path_length = boundary_path(&g, active, mut path)
			if path_length < 3 { return -1 }
			if reverse_index == 3 { break }
			reverse_index--
		}
		if path_length != 3 || path[0] != g.u || path[1] != order[2] || path[2] != g.v { return -1 }
	} else if order[2] != g.w { return -1 }
	mut position := []int{len: max_n}
	for i in 0 .. n { position[order[i]] = i }
	mut words := []i64{len: 1 + 4 * (max_n - 3)}
	words[0] = i64(n)
	mut count := 1
	for rank in 2 .. n - 1 {
		vertex := order[rank]
		mut left := -1
		mut right := -1
		if rank == 2 {
			if !g.adjacent[vertex * max_n + g.u] || !g.adjacent[vertex * max_n + g.v] { return -1 }
			left = g.u
			right = g.v
		} else {
			mut prefix := []bool{len: max_n}
			for i in 0 .. rank { prefix[order[i]] = true }
			mut boundary := []int{len: max_n}
			boundary_length := boundary_path(&g, prefix, mut boundary)
			if boundary_length < 3 { return -1 }
			mut ended := false
			mut boundary_count := 0
			for i in 0 .. boundary_length {
				if g.adjacent[vertex * max_n + boundary[i]] {
					if ended { return -1 }
					if left < 0 { left = boundary[i] }
					right = boundary[i]
					boundary_count++
				} else if left >= 0 { ended = true }
			}
			mut predecessor_count := 0
			for i in 0 .. rank { if g.adjacent[vertex * max_n + order[i]] { predecessor_count++ } }
			if boundary_count < 2 || boundary_count != predecessor_count { return -1 }
		}
		mut successor := -1
		for other in 0 .. n {
			if position[other] > rank && g.adjacent[vertex * max_n + other] && (successor < 0 || position[other] > position[successor]) { successor = other }
		}
		if successor < 0 { return -1 }
		words[count] = i64(vertex)
		words[count + 1] = i64(left)
		words[count + 2] = i64(right)
		words[count + 3] = i64(successor)
		count += 4
	}
	required := 8 * count
	if unsafe { output == nil } || capacity < usize(required) { return -2 }
	for index in 0 .. count { write_i64_le(mut output, 8 * index, words[index]) }
	return i64(required)
}
