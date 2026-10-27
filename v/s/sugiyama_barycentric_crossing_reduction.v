module sugiyama_barycentric_crossing_reduction

fn put_i64(mut output &u8, word int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[word * 8 + b] = u8((bits >> u64(8 * b)) & 255) } }
}

fn positions(order [8][32]int, sizes [8]int, layer int, mut pos [32]int) {
	for i in 0 .. sizes[layer] { pos[order[layer][i]] = i }
}

fn reorder(mut order [8][32]int, sizes [8]int, owner [32]int, eu [128]int,
	ev [128]int, edge_count int, target int, fixed int, downward bool, mut pos [32]int) {
	positions(order, sizes, fixed, mut pos)
	mut rank := [32]int{}
	mut numerator := [32]i64{}
	mut denominator := [32]i64{}
	for i in 0 .. sizes[target] { rank[order[target][i]] = i }
	for e in 0 .. edge_count {
		u := eu[e]
		v := ev[e]
		if downward && owner[u] == fixed && owner[v] == target {
			numerator[v] += i64(pos[u])
			denominator[v]++
		} else if !downward && owner[u] == target && owner[v] == fixed {
			numerator[u] += i64(pos[v])
			denominator[u]++
		}
	}
	for i in 0 .. sizes[target] {
		v := order[target][i]
		if denominator[v] == 0 { numerator[v] = i64(rank[v]); denominator[v] = 1 }
	}
	for i in 1 .. sizes[target] {
		vertex := order[target][i]
		mut j := i
		for j > 0 {
			previous := order[target][j - 1]
			left := numerator[vertex] * denominator[previous]
			right := numerator[previous] * denominator[vertex]
			if left > right || (left == right && rank[vertex] > rank[previous]) { break }
			order[target][j] = previous
			j--
		}
		order[target][j] = vertex
	}
	positions(order, sizes, target, mut pos)
}

@[export: 'sugiyama_barycentric_crossing_reduction']
pub fn sugiyama_barycentric_crossing_reduction(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 299 { return -1 }
	unsafe {
		layers0 := input[0]
		limit0 := input[1]
		if layers0 < 2 || layers0 > 8 || limit0 < 0 || limit0 > 16 { return -1 }
		layers := int(layers0)
		mut order := [8][32]int{}
		mut sizes := [8]int{}
		mut owner := [32]int{}
		for i in 0 .. 32 { owner[i] = -1 }
		mut pos := [32]int{}
		mut eu := [128]int{}
		mut ev := [128]int{}
		mut at := 2
		mut total := 0
		for level in 0 .. layers {
			if at >= int(length) { return -1 }
			count0 := input[at]
			at++
			if count0 < 1 || count0 > 32 || at + int(count0) > int(length) { return -1 }
			sizes[level] = int(count0)
			total += int(count0)
			if total > 32 { return -1 }
			for i in 0 .. sizes[level] {
				id0 := input[at]
				at++
				if id0 < 0 || id0 >= 32 { return -1 }
				id := int(id0)
				if owner[id] != -1 { return -1 }
				order[level][i] = id
				owner[id] = level
			}
		}
		if total < 2 || at >= int(length) { return -1 }
		edge0 := input[at]
		at++
		if edge0 < 0 || edge0 > 128 || at + 2 * int(edge0) != int(length) { return -1 }
		edge_count := int(edge0)
		for e in 0 .. edge_count {
			u0 := input[at + 2 * e]
			v0 := input[at + 2 * e + 1]
			if u0 < 0 || u0 >= 32 || v0 < 0 || v0 >= 32 { return -1 }
			u := int(u0)
			v := int(v0)
			if owner[u] < 0 || owner[v] != owner[u] + 1 { return -1 }
			for j in 0 .. e { if eu[j] == u && ev[j] == v { return -1 } }
			eu[e] = u
			ev[e] = v
		}
		mut sweeps := 0
		for _ in 0 .. int(limit0) {
			before := order
			for level in 0 .. layers - 1 {
				reorder(mut order, sizes, owner, eu, ev, edge_count, level + 1, level, true, mut pos)
			}
			for step in 0 .. layers - 1 {
				level := layers - 2 - step
				reorder(mut order, sizes, owner, eu, ev, edge_count, level, level + 1, false, mut pos)
			}
			sweeps++
			mut changed := false
			for l in 0 .. layers {
				for i in 0 .. sizes[l] { if before[l][i] != order[l][i] { changed = true } }
			}
			if !changed { break }
		}
		for l in 0 .. layers { positions(order, sizes, l, mut pos) }
		mut crossings := i64(0)
		for i in 0 .. edge_count {
			for j in i + 1 .. edge_count {
				if owner[eu[i]] == owner[eu[j]] &&
					(pos[eu[i]] - pos[eu[j]]) * (pos[ev[i]] - pos[ev[j]]) < 0 {
					crossings++
				}
			}
		}
		bytes := 8 * (total + 2)
		if output == nil || capacity < usize(bytes) { return -2 }
		put_i64(mut output, 0, i64(sweeps))
		put_i64(mut output, 1, crossings)
		mut word := 2
		for l in 0 .. layers {
			for i in 0 .. sizes[l] { put_i64(mut output, word, i64(order[l][i])); word++ }
		}
		return i64(bytes)
	}
}
