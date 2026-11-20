module commentz_walter

const cw_p = 6
const cw_l = 8
const cw_t = 64
const cw_nodes = 33
const cw_input = 105

fn cw_is_suffix(v int, u int, depth [cw_nodes]int, path [cw_nodes * cw_l]int) bool {
	if depth[v] >= depth[u] { return false }
	offset := depth[u] - depth[v]
	for i := 0; i < depth[v]; i++ {
		if path[v * cw_l + i] != path[u * cw_l + offset + i] { return false }
	}
	return true
}

@[export: 'commentz_walter']
pub fn commentz_walter(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > cw_input { return -1 }
		raw_p := values[0]
		raw_n := values[1]
		if raw_p < 1 || raw_p > cw_p || raw_n < 0 || raw_n > cw_t { return -1 }
		p := int(raw_p)
		n := int(raw_n)
		if length < usize(2 + p) { return -1 }
		mut lens := [cw_p]int{}
		mut total := 0
		mut shortest := cw_l + 1
		for i := 0; i < p; i++ {
			raw := values[2 + i]
			if raw < 1 || raw > cw_l { return -1 }
			lens[i] = int(raw)
			total += lens[i]
			if lens[i] < shortest { shortest = lens[i] }
		}
		if total > 32 || length != usize(2 + p + total + n) { return -1 }
		mut patterns := [cw_p * cw_l]i64{}
		mut text := [cw_t]i64{}
		mut at := 2 + p
		for i := 0; i < p; i++ {
			for j := 0; j < lens[i]; j++ {
				symbol := values[at]
				at++
				if symbol < 1 || symbol > 4 { return -1 }
				patterns[i * cw_l + j] = symbol
			}
			for prior := 0; prior < i; prior++ {
				if lens[prior] != lens[i] { continue }
				mut same := true
				for j := 0; j < lens[i]; j++ {
					if patterns[prior * cw_l + j] != patterns[i * cw_l + j] { same = false }
				}
				if same { return -1 }
			}
		}
		for i := 0; i < n; i++ {
			symbol := values[at]
			at++
			if symbol < 1 || symbol > 4 { return -1 }
			text[i] = symbol
		}

		mut child := [cw_nodes * 5]int{}
		mut parent := [cw_nodes]int{}
		mut label := [cw_nodes]int{}
		mut depth := [cw_nodes]int{}
		mut path := [cw_nodes * cw_l]int{}
		mut terminal := [cw_nodes]bool{}
		mut nodes := 1
		for i := 0; i < p; i++ {
			mut v := 0
			for j := lens[i] - 1; j >= 0; j-- {
				symbol := int(patterns[i * cw_l + j])
				mut encoded := child[v * 5 + symbol]
				if encoded == 0 {
					u := nodes
					nodes++
					child[v * 5 + symbol] = u + 1
					parent[u] = v
					label[u] = symbol
					depth[u] = depth[v] + 1
					for k := 0; k < depth[v]; k++ { path[u * cw_l + k] = path[v * cw_l + k] }
					path[u * cw_l + depth[v]] = symbol
					encoded = u + 1
				}
				v = encoded - 1
			}
			terminal[v] = true
		}

		mut shift1 := [cw_nodes]int{}
		mut shift2 := [cw_nodes]int{}
		mut bad := [5]int{}
		for v := 0; v < nodes; v++ { shift1[v] = shortest; shift2[v] = shortest }
		shift1[0] = 1
		for a := 0; a <= 4; a++ { bad[a] = shortest + 1 }
		for v := 1; v < nodes; v++ {
			if depth[v] < bad[label[v]] { bad[label[v]] = depth[v] }
			shift2[v] = shift2[parent[v]]
			for u := 1; u < nodes; u++ {
				if cw_is_suffix(v, u, depth, path) {
					delta := depth[u] - depth[v]
					if delta < shift1[v] { shift1[v] = delta }
					if terminal[u] && delta < shift2[v] { shift2[v] = delta }
				}
			}
		}

		mut matches := i64(0)
		mut position := shortest - 1
		for position < n {
			mut v := 0
			mut i := position
			for i >= 0 {
				encoded := child[v * 5 + int(text[i])]
				if encoded == 0 { break }
				v = encoded - 1
				i--
				if terminal[v] { matches++ }
			}
			symbol := if i >= 0 { int(text[i]) } else { 0 }
			char_shift := if symbol == 0 { shortest + 1 } else { bad[symbol] }
			delta := char_shift - depth[v] - 1
			if delta < shift1[v] { delta = shift1[v] }
			if delta > shift2[v] { delta = shift2[v] }
			position += delta
		}
		return matches
	}
}
