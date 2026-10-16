package fibonacci_heap

import "core:c"

MAX_NODES :: 128
Fib_Node :: struct { key: i64, parent, child, left, right, degree: int }

@(export)
fibonacci_heap :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if (values == nil && length > 0) || length > MAX_NODES do return -1
	n := int(length)
	for i := 0; i < n; i += 1 { if values[i] < -2_147_483_648 || values[i] > 2_147_483_647 do return -1 }
	if output_capacity < length * 8 || (length > 0 && output == nil) do return -2
	nodes: [MAX_NODES]Fib_Node
	minimum := -1
	add_root :: proc "contextless" (nodes: [^]Fib_Node, minimum: ^int, x: int) {
		nodes[x].parent = -1
		if minimum^ < 0 { nodes[x].left = x; nodes[x].right = x; minimum^ = x
		} else { m := minimum^; r := nodes[m].right; nodes[x].left = m; nodes[x].right = r; nodes[m].right = x; nodes[r].left = x; if nodes[x].key < nodes[m].key do minimum^ = x }
	}
	unlink :: proc "contextless" (nodes: [^]Fib_Node, x: int) { nodes[nodes[x].left].right = nodes[x].right; nodes[nodes[x].right].left = nodes[x].left }
	link :: proc "contextless" (nodes: [^]Fib_Node, parent, child: int) {
		nodes[child].parent = parent
		if nodes[parent].child < 0 { nodes[parent].child = child; nodes[child].left = child; nodes[child].right = child
		} else { c := nodes[parent].child; r := nodes[c].right; nodes[child].left = c; nodes[child].right = r; nodes[c].right = child; nodes[r].left = child }
		nodes[parent].degree += 1
	}
	for i := 0; i < n; i += 1 { nodes[i] = Fib_Node{key = values[i], parent = -1, child = -1, left = i, right = i}; add_root(&nodes[0], &minimum, i) }
	emitted := 0
	for minimum >= 0 {
		z := minimum; key := nodes[z].key
		if nodes[z].child >= 0 {
			kids: [MAX_NODES]int; count := 0; start := nodes[z].child; c := start
			for { kids[count] = c; count += 1; c = nodes[c].right; if c == start do break }
			for j := 0; j < count; j += 1 { unlink(&nodes[0], kids[j]); add_root(&nodes[0], &minimum, kids[j]) }
			nodes[z].child = -1; nodes[z].degree = 0
		}
		single := nodes[z].right == z
		unlink(&nodes[0], z)
		if single { minimum = -1 } else { minimum = nodes[z].right }
		if minimum >= 0 {
			roots: [MAX_NODES]int; root_count := 0; start := minimum; x := start
			for { roots[root_count] = x; root_count += 1; x = nodes[x].right; if x == start do break }
			table: [MAX_NODES]int; for i := 0; i < MAX_NODES; i += 1 { table[i] = -1 }
			for ri := 0; ri < root_count; ri += 1 {
				x = roots[ri]; d := nodes[x].degree
				if nodes[x].parent >= 0 do continue
				for table[d] >= 0 { y := table[d]; if nodes[y].key < nodes[x].key { tmp := x; x = y; y = tmp }; unlink(&nodes[0], y); link(&nodes[0], x, y); table[d] = -1; d = nodes[x].degree }
				table[d] = x
			}
			minimum = -1
			for i := 0; i < MAX_NODES; i += 1 { if table[i] >= 0 { q := table[i]; nodes[q].left = q; nodes[q].right = q; add_root(&nodes[0], &minimum, q) } }
		}
		bits := u64(key)
		for b := 0; b < 8; b += 1 { output[emitted * 8 + b] = u8((bits >> u64(b * 8)) & 0xff) }
		emitted += 1
	}
	return i64(emitted * 8)
}
