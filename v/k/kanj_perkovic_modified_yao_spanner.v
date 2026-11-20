module kanj_perkovic_modified_yao_spanner

const max_n = 16
const max_m = 42
const cone_count = 14
const max_darts = 84
const max_valid = 312
const max_parseable = 313

@[export: 'kanj_perkovic_modified_yao_spanner']
pub fn kanj_perkovic_modified_yao_spanner(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 3 || n64 > max_n || m64 < n64 - 1 || m64 > max_m || m64 > 3 * n64 - 6 { return -1 }
		n, m := int(n64), int(m64)
		dart_count := 2 * m
		if length != usize(2 + n + 7 * m) || length > max_valid { return -1 }
		mut edge_u := [max_m]int{}
		mut edge_v := [max_m]int{}
		mut weights := [max_m]i64{}
		mut adjacent := [max_n * max_n]bool{}
		mut expected_degree := [max_n]int{}
		mut source := [max_darts]int{}
		mut cone := [max_darts]int{}
		for e in 0 .. m {
			p := 2 + 5 * e
			u64, v64, weight := input[p], input[p + 1], input[p + 2]
			cu64, cv64 := input[p + 3], input[p + 4]
			if u64 < 0 || u64 >= v64 || v64 >= n64 || weight < 1 || weight > 1000000000000 ||
				cu64 < 0 || cu64 >= cone_count || cv64 < 0 || cv64 >= cone_count { return -1 }
			u, v := int(u64), int(v64)
			if e > 0 && (u < edge_u[e - 1] || (u == edge_u[e - 1] && v <= edge_v[e - 1])) { return -1 }
			edge_u[e], edge_v[e], weights[e] = u, v, weight
			adjacent[u * max_n + v] = true
			adjacent[v * max_n + u] = true
			expected_degree[u]++
			expected_degree[v]++
			source[2 * e], source[2 * e + 1] = u, v
			cone[2 * e], cone[2 * e + 1] = int(cu64), int(cv64)
		}
		mut rotation := [max_darts]int{}
		mut position := [max_darts]int{}
		mut row_start := [max_n]int{}
		mut degree := [max_n]int{}
		mut first := [max_n * cone_count]int{}
		mut after := [max_n * cone_count]int{}
		mut seen := [max_darts]bool{}
		for i in 0 .. max_n * cone_count { first[i] = -1; after[i] = -1 }
		mut cursor := 2 + 5 * m
		mut used := 0
		for v in 0 .. n {
			d64 := input[cursor]
			cursor++
			if d64 < 1 || d64 > max_darts || int(d64) != expected_degree[v] { return -1 }
			row_start[v] = used
			degree[v] = int(d64)
			mut previous := -1
			for _ in 0 .. degree[v] {
				raw := input[cursor]
				cursor++
				if raw < 0 || raw >= i64(dart_count) { return -1 }
				dart := int(raw)
				c := cone[dart]
				if seen[dart] || source[dart] != v || c < previous { return -1 }
				previous = c
				seen[dart] = true
				rotation[used] = dart
				position[dart] = used
				bucket := v * cone_count + c
				if first[bucket] < 0 { first[bucket] = used }
				after[bucket] = used + 1
				used++
			}
		}
		if cursor != int(length) || used != dart_count { return -1 }
		for d in 0 .. dart_count { if !seen[d] { return -1 } }
		mut reached := [max_n]bool{}
		mut queue := [max_n]int{}
		mut head := 0
		mut tail := 1
		queue[0] = 0
		reached[0] = true
		for head < tail {
			u := queue[head]
			head++
			for v in 0 .. n {
				if adjacent[u * max_n + v] && !reached[v] { reached[v] = true; queue[tail] = v; tail++ }
			}
		}
		if tail != n { return -1 }
		mut next_face := [max_darts]int{}
		mut face_seen := [max_darts]bool{}
		mut faces := 0
		for d in 0 .. dart_count {
			twin := d ^ 1
			dest := source[twin]
			local := position[twin] - row_start[dest]
			next_face[d] = rotation[row_start[dest] + (local + degree[dest] - 1) % degree[dest]]
		}
		for d in 0 .. dart_count {
			if !face_seen[d] {
				faces++
				mut current := d
				for !face_seen[current] { face_seen[current] = true; current = next_face[current] }
				if current != d { return -1 }
			}
		}
		if n - m + faces != 2 { return -1 }

		mut selected := [max_darts]bool{}
		for v in 0 .. n {
			for c in 0 .. cone_count {
				bucket := v * cone_count + c
				if first[bucket] < 0 { continue }
				mut best := -1
				for p := first[bucket]; p < after[bucket]; p++ {
					dart := rotation[p]
					e := dart / 2
					if best < 0 || weights[e] < weights[best / 2] ||
						(weights[e] == weights[best / 2] && e < best / 2) { best = dart }
				}
				selected[best] = true
			}
		}
		for v in 0 .. n {
			mut occupied := false
			for c in 0 .. cone_count { if first[v * cone_count + c] >= 0 { occupied = true } }
			if !occupied { continue }
			for start in 0 .. cone_count {
				if first[v * cone_count + start] >= 0 || first[v * cone_count + (start + cone_count - 1) % cone_count] < 0 { continue }
				mut run := 0
				for run < cone_count && first[v * cone_count + (start + run) % cone_count] < 0 { run++ }
				if run == 1 {
					cw_cone := (start + cone_count - 1) % cone_count
					ccw_cone := (start + 1) % cone_count
					cw := rotation[after[v * cone_count + cw_cone] - 1]
					ccw := rotation[first[v * cone_count + ccw_cone]]
					if selected[cw] { selected[ccw] = true }
					else if selected[ccw] { selected[cw] = true }
					else {
						a, b := cw / 2, ccw / 2
						if weights[a] < weights[b] || (weights[a] == weights[b] && a < b) { selected[cw] = true }
						else { selected[ccw] = true }
					}
				} else {
					mut cw_left := run / 2
					mut ccw_left := (run + 1) / 2
					for step in 1 .. cone_count + 1 {
						if cw_left == 0 { break }
						c := (start + cone_count - step) % cone_count
						bucket := v * cone_count + c
						if first[bucket] >= 0 {
							mut p := after[bucket] - 1
							for p >= first[bucket] && cw_left > 0 {
								dart := rotation[p]
								if !selected[dart] { selected[dart] = true; cw_left-- }
								p--
							}
						}
					}
					for step in run .. run + cone_count {
						if ccw_left == 0 { break }
						c := (start + step) % cone_count
						bucket := v * cone_count + c
						if first[bucket] >= 0 {
							for p := first[bucket]; p < after[bucket] && ccw_left > 0; p++ {
								dart := rotation[p]
								if !selected[dart] { selected[dart] = true; ccw_left-- }
							}
						}
					}
				}
			}
		}
		mut mask := u64(0)
		for e in 0 .. m { if selected[2 * e] && selected[2 * e + 1] { mask |= u64(1) << e } }
		return i64(mask)
	}
}
