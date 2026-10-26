// Clean-room bounded GARDENIA Forward-Backward-Trim SCC profile.
const max_n = 16
const max_m = 64
const max_input = 130
const max_tasks = 34

fn reach(active u32, pivot int, adjacency []u8, reverse bool, n int) u32 {
	mut seen := u32(1) << u32(pivot)
	for {
		mut expanded := seen
		for u in 0 .. n {
			ub := u32(1) << u32(u)
			if seen & ub == 0 || active & ub == 0 { continue }
			for v in 0 .. n {
				vb := u32(1) << u32(v)
				mut edge := adjacency[u * max_n + v] != 0
				if reverse { edge = adjacency[v * max_n + u] != 0 }
				if active & vb != 0 && edge { expanded |= vb }
			}
		}
		if expanded == seen { return seen }
		seen = expanded
	}
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits >> u64(8 * byte)) }
	}
}

@[export: 'gardenia_fb_trim_scc']
pub fn gardenia_fb_trim_scc(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 1 || n64 > max_n || m64 < 0 || m64 > max_m || length != usize(2 + 2 * m64) { return -1 }
		n, m := int(n64), int(m64)
		mut adjacency := [max_n * max_n]u8{}
		for e in 0 .. m {
			u64, v64 := input[2 + 2 * e], input[3 + 2 * e]
			if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 { return -1 }
			u, v := int(u64), int(v64)
			if adjacency[u * max_n + v] != 0 { return -1 }
			adjacency[u * max_n + v] = 1
		}
		output_bytes := usize(8 * n)
		if output == nil || capacity < output_bytes { return -2 }
		mut labels := [max_n]i64{}
		mut tasks := [max_tasks]u32{}
		mut task_count := 1
		tasks[0] = (u32(1) << u32(n)) - 1
		for task_count > 0 {
			task_count--
			mut active := tasks[task_count]
			for active != 0 {
				mut trimmed := u32(0)
				for u in 0 .. n {
					ub := u32(1) << u32(u)
					if active & ub == 0 { continue }
					mut has_in, has_out := false, false
					for v in 0 .. n {
						if active & (u32(1) << u32(v)) == 0 { continue }
						has_out = has_out || adjacency[u * max_n + v] != 0
						has_in = has_in || adjacency[v * max_n + u] != 0
					}
					if !has_in || !has_out { trimmed |= ub }
				}
				if trimmed == 0 { break }
				for u in 0 .. n { if trimmed & (u32(1) << u32(u)) != 0 { labels[u] = i64(u) } }
				active &= ~trimmed
			}
			if active == 0 { continue }
			mut pivot := 0
			for active & (u32(1) << u32(pivot)) == 0 { pivot++ }
			forward := reach(active, pivot, adjacency[..], false, n)
			backward := reach(active, pivot, adjacency[..], true, n)
			component := forward & backward
			mut representative := 0
			for component & (u32(1) << u32(representative)) == 0 { representative++ }
			for u in 0 .. n { if component & (u32(1) << u32(u)) != 0 { labels[u] = i64(representative) } }
			children := [3]u32{active & ~(forward | backward), forward & ~backward, backward & ~forward}
			for child in children {
				if child != 0 {
					if task_count >= max_tasks { return -1 }
					tasks[task_count] = child
					task_count++
				}
			}
		}
		for u in 0 .. n { put_i64_le(mut output, 8 * u, labels[u]) }
		return i64(output_bytes)
	}
}
