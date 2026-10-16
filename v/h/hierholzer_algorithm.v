module hierholzer_algorithm

fn record_hash(record []i64) i64 {
	mut hash := u64(14695981039346656037)
	for word in record {
		bits := u64(word)
		for byte in 0 .. 8 {
			hash ^= (bits >> u64(byte * 8)) & 255
			hash *= u64(1099511628211)
		}
	}
	return i64(hash & u64(0x7fffffffffffffff))
}

@[export: 'hierholzer_algorithm']
pub fn hierholzer_algorithm(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 514 { return -1 }
	unsafe {
		n64 := input[0]
		m64 := input[1]
		if n64 < 0 || n64 > 8 || m64 < 0 || m64 > 256 { return -1 }
		n := int(n64)
		m := int(m64)
		if length != usize(2 + 2 * m) || (n == 0 && m != 0) { return -1 }
		mut adj := [8][512]int{}
		mut degree := [8]int{}
		for edge in 0 .. m {
			u64 := input[2 + 2 * edge]
			v64 := input[3 + 2 * edge]
			if u64 < 0 || v64 < 0 || u64 >= n64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			adj[u][degree[u]] = v
			degree[u]++
			adj[v][degree[v]] = u
			degree[v]++
		}
		if n == 0 { return record_hash([i64(1), i64(0)]) }
		mut start := 0
		mut has_edge := false
		for v in 0 .. n { if degree[v] > 0 && !has_edge { start = v; has_edge = true } }
		if !has_edge { return record_hash([i64(1), i64(1), i64(0)]) }
		mut seen := [8]bool{}
		mut queue := [8]int{}
		mut head := 0
		mut tail := 1
		queue[0] = start
		seen[start] = true
		for head < tail {
			v := queue[head]
			head++
			for w in 0 .. n {
				if degree[w] > 0 && !seen[w] {
					for j in 0 .. degree[w] { if adj[w][j] == v { seen[w] = true; queue[tail] = w; tail++; break } }
				}
			}
		}
		for v in 0 .. n { if degree[v] % 2 != 0 || (degree[v] > 0 && !seen[v]) { return record_hash([i64(0), i64(0)]) } }
		mut lengths := degree
		mut stack := [258]int{}
		mut stack_len := 1
		stack[0] = start
		mut route := [258]int{}
		mut route_len := 0
		for stack_len > 0 {
			v := stack[stack_len - 1]
			if lengths[v] > 0 {
				w := adj[v][0]
				for j in 0 .. lengths[v] - 1 { adj[v][j] = adj[v][j + 1] }
				lengths[v]--
				mut k := 0
				for k < lengths[w] && adj[w][k] != v { k++ }
				if k < lengths[w] { for j in k .. lengths[w] - 1 { adj[w][j] = adj[w][j + 1] }; lengths[w]-- }
				stack[stack_len] = w
				stack_len++
			} else { stack_len--; route[route_len] = v; route_len++ }
		}
		if route_len != m + 1 { return record_hash([i64(0), i64(0)]) }
		mut record := []i64{cap: route_len + 2}
		record << i64(1)
		record << i64(route_len)
		for i in 0 .. route_len { record << i64(route[route_len - 1 - i]) }
		return record_hash(record)
	}
}
