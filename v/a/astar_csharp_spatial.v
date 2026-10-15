module astar_csharp_spatial

import math

const max_nodes = 16

struct SpatialNode {
	mut:
		x f64
		y f64
		multiplier f64
		current f64
		estimated f64
		traversable bool
		state int
		parent int
}

fn distance(nodes []SpatialNode, a int, b int) f64 {
	dx := nodes[a].x - nodes[b].x
	dy := nodes[a].y - nodes[b].y
	return math.sqrt(dx * dx + dy * dy)
}

fn total(nodes []SpatialNode, i int) f64 { return nodes[i].current + nodes[i].estimated }

fn enqueue(mut heap []int, mut count int, value int, nodes []SpatialNode) {
	mut i := count
	count++
	for i > 0 {
		p := (i - 1) / 2
		if total(nodes, heap[p]) <= total(nodes, value) { break }
		heap[i] = heap[p]
		i = p
	}
	heap[i] = value
}

fn dequeue(mut heap []int, mut count int, nodes []SpatialNode) int {
	target := heap[0]
	count--
	root := heap[count]
	mut i := 0
	for i * 2 + 1 < count {
		left := i * 2 + 1
		right := i * 2 + 2
		child := if right < count && total(nodes, heap[right]) < total(nodes, heap[left]) { right } else { left }
		if total(nodes, heap[child]) >= total(nodes, root) { break }
		heap[i] = heap[child]
		i = child
	}
	if count > 0 { heap[i] = root }
	return target
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset + b] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'astar_csharp_spatial']
pub fn astar_csharp_spatial(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 { return -1 }
	n64 := unsafe { input[0] }; m64 := unsafe { input[1] }; s64 := unsafe { input[2] }; g64 := unsafe { input[3] }
	if n64 < 2 || n64 > max_nodes || m64 != n64 - 1 || s64 < 0 || s64 >= n64 || g64 < 0 || g64 >= n64 { return -1 }
	n := int(n64); m := int(m64); start := int(s64); goal := int(g64); edge := 4 + 4 * n
	if length != usize(4 + 4 * n + 2 * m) { return -1 }
	mut nodes := []SpatialNode{len: n}
	mut parents := []int{len: n}; mut seen := []bool{len: n}; mut stack := []int{cap: max_nodes}
	unsafe {
		for i in 0 .. n {
			o := 4 + 4 * i; x := input[o]; y := input[o + 1]; t := input[o + 2]; multiplier := input[o + 3]
			if x < -1000 || x > 1000 || y < -1000 || y > 1000 || (t != 0 && t != 1) || multiplier < 1 || multiplier > 4 { return -1 }
			nodes[i] = SpatialNode{x: f64(x), y: f64(y), multiplier: f64(multiplier), traversable: t == 1, parent: -1}
			for j in 0 .. i { if nodes[i].x == nodes[j].x && nodes[i].y == nodes[j].y { return -1 } }
		}
		for e in 0 .. m {
			u := input[edge + 2 * e]; v := input[edge + 2 * e + 1]
			if u < 0 || u >= n64 || v < 0 || v >= n64 || u == v { return -1 }
			parents[int(v)]++
			if parents[int(v)] > 1 { return -1 }
			for p in 0 .. e { if input[edge + 2 * p] == u && input[edge + 2 * p + 1] == v { return -1 } }
		}
		if parents[start] != 0 { return -1 }
		for i in 0 .. n { if i != start && parents[i] != 1 { return -1 } }
		stack << start
		mut visited := 0
		for stack.len > 0 {
			u := stack.pop()
			if seen[u] { continue }
			seen[u] = true; visited++
			for e in 0 .. m { if input[edge + 2 * e] == i64(u) { stack << int(input[edge + 2 * e + 1]) } }
		}
		if visited != n { return -1 }
		mut heap := []int{len: max_nodes}; mut heap_count := 0
		for e in 0 .. m {
			if input[edge + 2 * e] == i64(start) {
				v := int(input[edge + 2 * e + 1])
				if nodes[v].traversable { nodes[v].current = distance(nodes, start, v) * nodes[v].multiplier; nodes[v].estimated = distance(nodes, v, goal); enqueue(mut heap, mut heap_count, v, nodes) }
			}
		}
		mut path := []int{cap: max_nodes}; mut path_count := 0
		for heap_count > 0 {
			u := dequeue(mut heap, mut heap_count, nodes); nodes[u].state = 2
			if total(nodes, u) == total(nodes, goal) { mut q := goal; for q >= 0 && path_count < max_nodes { path << q; path_count++; q = nodes[q].parent }; break }
			for e in 0 .. m {
				if input[edge + 2 * e] != i64(u) { continue }
				v := int(input[edge + 2 * e + 1]); if !nodes[v].traversable || nodes[v].state == 2 { continue }
				if nodes[v].state == 0 {
					nodes[v].parent = u; nodes[v].current = nodes[u].current + distance(nodes, u, v) * nodes[v].multiplier
					nodes[v].estimated = nodes[v].current + distance(nodes, v, goal); nodes[v].state = 1
					enqueue(mut heap, mut heap_count, v, nodes)
				} else if total(nodes, u) != total(nodes, v) {
					ng := nodes[u].current + distance(nodes, u, v); nf := ng + nodes[u].estimated
					if nf < total(nodes, v) { nodes[v].parent = u; nodes[v].current = ng }
				} else { return -1 }
			}
		}
		bytes := path_count * 8
		if bytes == 0 { return 0 }
		if output == nil || capacity < usize(bytes) { return -2 }
		for i in 0 .. path_count { put_i64_le(mut output, i * 8, i64(path[path_count - 1 - i])) }
		return i64(bytes)
	}
}
