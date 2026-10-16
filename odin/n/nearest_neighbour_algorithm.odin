package nearest_neighbour_algorithm

import "core:c"

@(export)
nearest_neighbour_algorithm :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 257 || values[0] < 1 || values[0] > 16 do return -1
	n := int(values[0]); if int(length) != 1+n*n do return -1
	for i := 1; i < int(length); i += 1 { if values[i] < 0 || values[i] > 1000000 do return -1 }
	seen: [16]bool
	path: [16]int
	current := 0
	for step := 0; step < n; step += 1 {
		path[step] = current; seen[current] = true
		if step+1 < n {
			best := n; distance: i64 = 0
			for j := 0; j < n; j += 1 { if !seen[j] { d := values[1+current*n+j]; if best == n || d < distance { best = j; distance = d } } }
			current = best
		}
	}
	buffer: [64]u8
	used := 0
	for i := 0; i < n; i += 1 {
		if i > 0 { buffer[used] = ','; used += 1 }
		x := path[i]
		if x >= 10 { buffer[used] = u8('0' + x/10); used += 1 }
		buffer[used] = u8('0' + x%10); used += 1
	}
	if c.size_t(used) > capacity || (used > 0 && output == nil) do return -2
	for i := 0; i < used; i += 1 { output[i] = buffer[i] }
	return i64(used)
}
