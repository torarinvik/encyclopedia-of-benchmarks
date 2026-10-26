package gapbs_shiloach_vishkin_components

import "core:c"

@(export)
gapbs_shiloach_vishkin_components :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 130 do return -1
	n64, m64 := input[0], input[1]
	if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || length != c.size_t(2+2*m64) do return -1
	n, m := int(n64), int(m64)
	adjacency: [256]bool
	for edge := 0; edge < m; edge += 1 {
		pos := 2 + 2*edge
		u, v := input[pos], input[pos+1]
		if u < 0 || v <= u || v >= n64 do return -1
		ui, vi := int(u), int(v)
		if adjacency[ui*16+vi] do return -1
		adjacency[ui*16+vi] = true
		adjacency[vi*16+ui] = true
	}
	output_bytes := 8*n
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	component: [16]int
	for node := 0; node < n; node += 1 do component[node] = node
	changed := true
	rounds := 0
	round_limit := n*n + 1
	for changed && rounds < round_limit {
		changed = false
		for u := 0; u < n; u += 1 {
			for v := 0; v < n; v += 1 {
				if !adjacency[u*16+v] do continue
				component_u, component_v := component[u], component[v]
				if component_u == component_v do continue
				high := max(component_u, component_v)
				low := min(component_u, component_v)
				if component[high] == high { changed = true; component[high] = low }
			}
		}
		for node := 0; node < n; node += 1 {
			for component[node] != component[component[node]] do component[node] = component[component[node]]
		}
		rounds += 1
	}
	if changed do return -1
	for node := 0; node < n; node += 1 {
		bits := u64(component[node])
		for byte := 0; byte < 8; byte += 1 do output[8*node+byte] = u8((bits >> (8*byte)) & 255)
	}
	return i64(output_bytes)
}
