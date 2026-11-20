module z

const max_n = 8
const inf_dist = u8(9)

struct BridgeState {
	n int
	threshold int
	edge [64]u8
	witness [64]u8
	distance [64]u8
	constraints [64]u16
	constraint_count int
}

struct Prefix {
	values [8]u8
	count int
}

fn popcount16(mask u16) int {
	mut value := mask
	mut count := 0
	for value != 0 {
		count += int(value & 1)
		value >>= 1
	}
	return count
}

fn subpath(state &BridgeState, from int, to int, limit int) Prefix {
	mut result := Prefix{}
	encoded := state.witness[from * state.n + to]
	if limit <= 0 || encoded == 0 { return result }
	middle := int(encoded) - 1
	left := subpath(state, from, middle, limit - 1)
	result = left
	result.values[result.count] = u8(middle)
	result.count++
	remaining := limit - result.count
	if remaining > 0 {
		right := subpath(state, middle, to, remaining)
		for i in 0 .. right.count {
			result.values[result.count] = right.values[i]
			result.count++
		}
	}
	return result
}

@[export: 'zwick_deterministic_bridging_set']
pub fn zwick_deterministic_bridging_set(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 131 { return -1 }
		if input[0] < 2 || input[0] > max_n { return -1 }
		n := int(input[0])
		if input[1] < 2 || input[1] > i64(n) || length != usize(2 + 2*n*n) { return -1 }
		mut state := BridgeState{n: n, threshold: int(input[1])}
		matrix := n * n
		for i in 0 .. matrix {
			if input[2+i] < 0 || input[2+i] > 1 || input[2+matrix+i] < 0 || input[2+matrix+i] > i64(n) { return -1 }
			state.edge[i] = u8(input[2+i])
			state.witness[i] = u8(input[2+matrix+i])
		}
		for i in 0 .. n {
			if state.edge[i*n+i] != 0 { return -1 }
			for j in 0 .. n {
				state.distance[i*n+j] = if i == j { u8(0) } else if state.edge[i*n+j] != 0 { u8(1) } else { inf_dist }
			}
		}
		for k in 0 .. n {
			for i in 0 .. n {
				for j in 0 .. n {
					candidate := int(state.distance[i*n+k]) + int(state.distance[k*n+j])
					if candidate < int(state.distance[i*n+j]) { state.distance[i*n+j] = u8(candidate) }
				}
			}
		}
		for i in 0 .. n {
			for j in 0 .. n {
				d := int(state.distance[i*n+j])
				w := int(state.witness[i*n+j])
				if d >= int(inf_dist) { return -1 }
				if d <= 1 {
					if w != 0 { return -1 }
				} else {
					if w == 0 { return -1 }
					v := w - 1
					if v == i || v == j { return -1 }
					left, right := int(state.distance[i*n+v]), int(state.distance[v*n+j])
					if left+right != d || left >= d || right >= d { return -1 }
				}
			}
		}
		for i in 0 .. n {
			for j in 0 .. n {
				prefix := subpath(&state, i, j, state.threshold)
				mut mask := (u16(1) << i) | (u16(1) << j)
				for k in 0 .. prefix.count { mask |= u16(1) << prefix.values[k] }
				if popcount16(mask) >= state.threshold {
					mut duplicate := false
					for c in 0 .. state.constraint_count { if state.constraints[c] == mask { duplicate = true } }
					if !duplicate { state.constraints[state.constraint_count] = mask; state.constraint_count++ }
				}
			}
		}
		mut unhit := [64]bool{}
		for c in 0 .. state.constraint_count { unhit[c] = true }
		mut remaining := state.constraint_count
		mut selected := u16(0)
		for remaining > 0 {
			mut best_vertex, best_score := 0, 0
			for v in 0 .. n {
				mut score := 0
				for c in 0 .. state.constraint_count { if unhit[c] && (state.constraints[c] & (u16(1) << v)) != 0 { score++ } }
				if score > best_score { best_vertex, best_score = v, score }
			}
			if best_score == 0 { return -1 }
			selected |= u16(1) << best_vertex
			for c in 0 .. state.constraint_count {
				if unhit[c] && (state.constraints[c] & (u16(1) << best_vertex)) != 0 {
					unhit[c] = false
					remaining--
				}
			}
		}
		return i64(selected)
	}
}
