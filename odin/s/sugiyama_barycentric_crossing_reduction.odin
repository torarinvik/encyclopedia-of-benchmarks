package sugiyama_barycentric_crossing_reduction

import "core:c"

put_i64 :: proc(out: [^]u8, word: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[word*8+b] = u8((bits >> u64(8*b)) & 255) }
}

positions :: proc(order: ^[256]i64, sizes: [8]int, layer: int, pos: ^[32]int) {
	for i := 0; i < sizes[layer]; i += 1 { pos[cast(int)order^[layer*32+i]] = i }
}

reorder :: proc(order: ^[256]i64, sizes: [8]int, owner: [32]int,
	eu: [128]int, ev: [128]int, edge_count, target, fixed: int, down: bool,
	pos: ^[32]int) {
	positions(order, sizes, fixed, pos)
	rank: [32]int
	num: [32]i64
	den: [32]i64
	for i := 0; i < sizes[target]; i += 1 { rank[cast(int)order^[target*32+i]] = i }
	for e := 0; e < edge_count; e += 1 {
		u := eu[e]
		v := ev[e]
		if down && owner[u] == fixed && owner[v] == target {
			num[v] += i64(pos[u])
			den[v] += 1
		} else if !down && owner[u] == target && owner[v] == fixed {
			num[u] += i64(pos[v])
			den[u] += 1
		}
	}
	for i := 0; i < sizes[target]; i += 1 {
		v := cast(int)order^[target*32+i]
		if den[v] == 0 { num[v] = i64(rank[v]); den[v] = 1 }
	}
	for i := 1; i < sizes[target]; i += 1 {
		vertex := cast(int)order^[target*32+i]
		j := i
		for j > 0 {
			previous := cast(int)order^[target*32+j-1]
			left := num[vertex] * den[previous]
			right := num[previous] * den[vertex]
			if left > right || (left == right && rank[vertex] > rank[previous]) { break }
			order^[target*32+j] = order^[target*32+j-1]
			j -= 1
		}
		order^[target*32+j] = i64(vertex)
	}
	positions(order, sizes, target, pos)
}

sugiyama_barycentric_crossing_reduction :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 299 do return -1
	layer0 := input[0]
	limit0 := input[1]
	if layer0 < 2 || layer0 > 8 || limit0 < 0 || limit0 > 16 do return -1
	layers := int(layer0)
	order: [256]i64
	sizes: [8]int
	owner: [32]int
	for i := 0; i < 32; i += 1 { owner[i] = -1 }
	pos: [32]int
	eu: [128]int
	ev: [128]int
	at := 2
	total := 0
	for level := 0; level < layers; level += 1 {
		if at >= int(length) do return -1
		count0 := input[at]
		at += 1
		if count0 < 1 || count0 > 32 || at + int(count0) > int(length) do return -1
		sizes[level] = int(count0)
		total += int(count0)
		if total > 32 do return -1
		for i := 0; i < sizes[level]; i += 1 {
			id0 := input[at]
			at += 1
			if id0 < 0 || id0 >= 32 do return -1
			id := int(id0)
			if owner[id] != -1 do return -1
			order[level*32+i] = id0
			owner[id] = level
		}
	}
	if total < 2 || at >= int(length) do return -1
	edge0 := input[at]
	at += 1
	if edge0 < 0 || edge0 > 128 || at + 2*int(edge0) != int(length) do return -1
	edge_count := int(edge0)
	for e := 0; e < edge_count; e += 1 {
		u0 := input[at+2*e]
		v0 := input[at+2*e+1]
		if u0 < 0 || u0 >= 32 || v0 < 0 || v0 >= 32 do return -1
		u := int(u0)
		v := int(v0)
		if owner[u] < 0 || owner[v] != owner[u]+1 do return -1
		for j := 0; j < e; j += 1 { if eu[j] == u && ev[j] == v do return -1 }
		eu[e] = u
		ev[e] = v
	}
	sweeps := 0
	for pass := 0; pass < int(limit0); pass += 1 {
		before: [256]i64
		for i := 0; i < 256; i += 1 { before[i] = order[i] }
		for level := 0; level < layers-1; level += 1 {
			reorder(&order, sizes, owner, eu, ev, edge_count, level+1, level, true, &pos)
		}
		for step := 0; step < layers-1; step += 1 {
			level := layers-2-step
			reorder(&order, sizes, owner, eu, ev, edge_count, level, level+1, false, &pos)
		}
		sweeps += 1
		changed := false
		for l := 0; l < layers; l += 1 {
			for i := 0; i < sizes[l]; i += 1 {
				if before[l*32+i] != order[l*32+i] do changed = true
			}
		}
		if !changed do break
	}
	for l := 0; l < layers; l += 1 { positions(&order, sizes, l, &pos) }
	crossings: i64 = 0
	for i := 0; i < edge_count; i += 1 {
		for j := i+1; j < edge_count; j += 1 {
			if owner[eu[i]] == owner[eu[j]] &&
				(pos[eu[i]]-pos[eu[j]])*(pos[ev[i]]-pos[ev[j]]) < 0 do crossings += 1
		}
	}
	bytes := 8*(total+2)
	if output == nil || capacity < c.size_t(bytes) do return -2
	put_i64(output, 0, i64(sweeps))
	put_i64(output, 1, crossings)
	word := 2
	for l := 0; l < layers; l += 1 {
		for i := 0; i < sizes[l]; i += 1 { put_i64(output, word, order[l*32+i]); word += 1 }
	}
	return i64(bytes)
}
