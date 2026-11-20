module havel_hakimi_graph_realization

const max_n = 8
const max_edges = 28
const max_input = 10

fn store_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'havel_hakimi_graph_realization']
pub fn havel_hakimi_graph_realization(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input { return -1 }
	unsafe {
		n_value := input[0]
		if n_value < 0 || n_value > max_n { return -1 }
		n := int(n_value)
		if length != usize(n + 1) { return -1 }
		mut residual := [max_n]int{init: 0}
		mut active := [max_n]bool{init: false}
		for v in 0 .. n {
			d := input[v + 1]
			if d < 0 || d >= n_value { return -1 }
			residual[v] = int(d); active[v] = true
		}
		mut left := [max_edges]i64{init: 0}
		mut right := [max_edges]i64{init: 0}
		mut edge_count := 0
		mut graphical := true
		for graphical {
			mut hub := -1
			for v in 0 .. n {
				if active[v] && residual[v] > 0 && (hub < 0 || residual[v] > residual[hub] || (residual[v] == residual[hub] && v < hub)) { hub = v }
			}
			if hub < 0 { break }
			d := residual[hub]; residual[hub] = 0; active[hub] = false
			mut candidates := [max_n]int{init: 0}
			mut count := 0
			for v in 0 .. n { if active[v] { candidates[count] = v; count++ } }
			for i in 1 .. count {
				value := candidates[i]; mut j := i
				for j > 0 && (residual[candidates[j - 1]] < residual[value] || (residual[candidates[j - 1]] == residual[value] && candidates[j - 1] > value)) { candidates[j] = candidates[j - 1]; j-- }
				candidates[j] = value
			}
			if d > count { graphical = false; break }
			for i in 0 .. d {
				neighbor := candidates[i]
				if residual[neighbor] == 0 { graphical = false; break }
				residual[neighbor]--
				left[edge_count] = i64(if hub < neighbor { hub } else { neighbor })
				right[edge_count] = i64(if hub < neighbor { neighbor } else { hub })
				edge_count++
			}
		}
		mut words := [2 + 2 * max_edges]i64{init: 0}
		mut used := 0
		if graphical {
			words[0] = 1; words[1] = i64(edge_count); used = 2 + 2 * edge_count
			for i in 0 .. edge_count { words[2 + 2 * i] = left[i]; words[3 + 2 * i] = right[i] }
		} else { words[0] = 0; used = 1 }
		byte_count := used * 8
		if output == nil || capacity < usize(byte_count) { return -2 }
		mut encoded := [464]u8{init: 0}
		for i in 0 .. used { store_i64(mut encoded[0], i * 8, words[i]) }
		for i in 0 .. byte_count { output[i] = encoded[i] }
		return i64(byte_count)
	}
}
