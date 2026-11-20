module fast_minimal_triangulation

const nmax = 8
const mmax = 28
const max_input = 59

fn put_word(output &u8, at int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[at + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

fn recurse(vertices u16, graph [8]u16) u64 {
	mut complete := true
	for u in 0 .. nmax {
		if ((vertices >> u) & 1) != 0 {
			others := vertices & ~(u16(1) << u)
			if graph[u] & others != others { complete = false }
		}
	}
	if complete { return 0 }
	mut pivot := 0
	for pivot < nmax {
		if ((vertices >> pivot) & 1) != 0 {
			others := vertices & ~(u16(1) << pivot)
			if graph[pivot] & others != others { break }
		}
		pivot++
	}
	a := (u16(1) << pivot) | (graph[pivot] & vertices)
	mut unseen := vertices & ~a
	mut components := [8]u16{}
	mut closures := [8]u16{}
	mut count := 0
	for unseen != 0 {
		mut seed := 0
		for ((unseen >> seed) & 1) == 0 { seed++ }
		mut comp := u16(1) << seed
		unseen &= ~comp
		mut frontier := comp
		for frontier != 0 {
			mut u := 0
			for ((frontier >> u) & 1) == 0 { u++ }
			frontier &= ~(u16(1) << u)
			added := graph[u] & unseen
			comp |= added
			frontier |= added
			unseen &= ~added
		}
		components[count] = comp
		count++
	}
	mut saturated := graph
	mut result := u64(0)
	for ci in 0 .. count {
		comp := components[ci]
		mut boundary := u16(0)
		for u in 0 .. nmax { if ((comp >> u) & 1) != 0 { boundary |= graph[u] & vertices & ~comp } }
		closures[ci] = comp | boundary
		for u in 0 .. nmax {
			if ((boundary >> u) & 1) == 0 { continue }
			for v in u + 1 .. nmax {
				if ((boundary >> v) & 1) != 0 && ((saturated[u] >> v) & 1) == 0 {
					saturated[u] |= u16(1) << v
					saturated[v] |= u16(1) << u
					result |= u64(1) << (u * nmax + v)
				}
			}
		}
	}
	result |= recurse(a, saturated)
	for ci in 0 .. count { result |= recurse(closures[ci], saturated) }
	return result
}

@[export: 'fast_minimal_triangulation']
pub fn fast_minimal_triangulation(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 1 || n64 > nmax || m64 < 0 || m64 > mmax || length != usize(2 + 2 * m64) { return -1 }
		n, m := int(n64), int(m64)
		mut graph := [8]u16{}
		mut original := u64(0)
		mut previous_u := i64(-1); mut previous_v := i64(-1)
		for i in 0 .. m {
			u64, v64 := input[2 + 2 * i], input[3 + 2 * i]
			if u64 < 0 || v64 <= u64 || v64 >= n64 || u64 < previous_u || (u64 == previous_u && v64 <= previous_v) { return -1 }
			previous_u, previous_v = u64, v64
			u, v := int(u64), int(v64)
			graph[u] |= u16(1) << v; graph[v] |= u16(1) << u
			original |= u64(1) << (u * nmax + v)
		}
		fill := recurse((u16(1) << n) - 1, graph) & ~original
		mut count := 0
		for u in 0 .. n { for v in u + 1 .. n { if ((fill >> (u*nmax+v)) & 1) != 0 { count++ } } }
		bytes := 8 * (1 + 2 * count)
		if output == nil || capacity < bytes { return -2 }
		put_word(output, 0, i64(count))
		mut index := 1
		for u in 0 .. n { for v in u + 1 .. n {
			if ((fill >> (u*nmax+v)) & 1) != 0 { put_word(output, 8*index, i64(u)); index++; put_word(output, 8*index, i64(v)); index++ }
		} }
		return i64(bytes)
	}
}
