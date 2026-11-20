package commentz_walter

import "core:c"

CW_P :: 6
CW_L :: 8
CW_T :: 64
CW_NODES :: 33
CW_INPUT :: 105

cw_is_suffix :: proc(v, u: int, depth: [CW_NODES]int,
                     path: [CW_NODES][CW_L]i64) -> bool {
	if depth[v] >= depth[u] do return false
	offset := depth[u] - depth[v]
	for i := 0; i < depth[v]; i += 1 {
		if path[v][i] != path[u][offset+i] do return false
	}
	return true
}

@(export)
commentz_walter :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > CW_INPUT do return -1
	raw_p, raw_n := values[0], values[1]
	if raw_p < 1 || raw_p > CW_P || raw_n < 0 || raw_n > CW_T do return -1
	p, n := int(raw_p), int(raw_n)
	if length < c.size_t(2+p) do return -1
	lens: [CW_P]int
	total, shortest := 0, CW_L+1
	for i := 0; i < p; i += 1 {
		raw := values[2+i]
		if raw < 1 || raw > CW_L do return -1
		lens[i] = int(raw)
		total += lens[i]
		if lens[i] < shortest do shortest = lens[i]
	}
	if total > 32 || length != c.size_t(2+p+total+n) do return -1
	patterns: [CW_P][CW_L]i64
	text: [CW_T]i64
	at := 2+p
	for i := 0; i < p; i += 1 {
		for j := 0; j < lens[i]; j += 1 {
			symbol := values[at]; at += 1
			if symbol < 1 || symbol > 4 do return -1
			patterns[i][j] = symbol
		}
		for prior := 0; prior < i; prior += 1 {
			if lens[prior] != lens[i] do continue
			same := true
			for j := 0; j < lens[i]; j += 1 { if patterns[prior][j] != patterns[i][j] do same = false }
			if same do return -1
		}
	}
	for i := 0; i < n; i += 1 {
		symbol := values[at]; at += 1
		if symbol < 1 || symbol > 4 do return -1
		text[i] = symbol
	}

	child: [CW_NODES][5]int
	parent, label, depth: [CW_NODES]int
	path: [CW_NODES][CW_L]i64
	terminal: [CW_NODES]bool
	nodes := 1
	for i := 0; i < p; i += 1 {
		v := 0
		for j := lens[i]-1; j >= 0; j -= 1 {
			symbol := int(patterns[i][j])
			encoded := child[v][symbol]
			if encoded == 0 {
				u := nodes; nodes += 1
				child[v][symbol] = u+1
				parent[u] = v; label[u] = symbol; depth[u] = depth[v]+1
				for k := 0; k < depth[v]; k += 1 { path[u][k] = path[v][k] }
				path[u][depth[v]] = i64(symbol)
				encoded = u+1
			}
			v = encoded-1
		}
		terminal[v] = true
	}
	shift1, shift2: [CW_NODES]int
	bad: [5]int
	for v := 0; v < nodes; v += 1 { shift1[v] = shortest; shift2[v] = shortest }
	shift1[0] = 1
	for a := 0; a <= 4; a += 1 { bad[a] = shortest+1 }
	for v := 1; v < nodes; v += 1 {
		if depth[v] < bad[label[v]] do bad[label[v]] = depth[v]
		shift2[v] = shift2[parent[v]]
		for u := 1; u < nodes; u += 1 {
			if cw_is_suffix(v,u,depth,path) {
				delta := depth[u]-depth[v]
				if delta < shift1[v] do shift1[v] = delta
				if terminal[u] && delta < shift2[v] do shift2[v] = delta
			}
		}
	}
	matches: i64 = 0
	position := shortest-1
	for position < n {
		v, i := 0, position
		for i >= 0 {
			encoded := child[v][int(text[i])]
			if encoded == 0 do break
			v = encoded-1; i -= 1
			if terminal[v] do matches += 1
		}
		symbol := 0
		if i >= 0 do symbol = int(text[i])
		char_shift := shortest+1
		if symbol != 0 do char_shift = bad[symbol]
		delta := char_shift-depth[v]-1
		if delta < shift1[v] do delta = shift1[v]
		if delta > shift2[v] do delta = shift2[v]
		position += delta
	}
	return matches
}
