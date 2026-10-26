module approximating_diameter_bfs

fn put_i64(mut output &u8, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[b] = u8((bits >> u64(8*b)) & 255) } }
}

@[export: 'approximating_diameter_bfs']
pub fn approximating_diameter_bfs(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 242 { return -1 }
	unsafe {
		n0, m0 := input[0], input[1]
		if n0 < 1 || n0 > 16 || m0 < 0 || m0 > 120 || length != usize(2+2*m0) { return -1 }
		n, m := int(n0), int(m0)
		mut adj := []bool{len: 256, init: false}
		for i in 0 .. m {
			u0, v0 := input[2+2*i], input[3+2*i]
			if u0 < 0 || v0 <= u0 || v0 >= n0 { return -1 }
			u, v := int(u0), int(v0)
			if adj[u*16+v] { return -1 }
			adj[u*16+v] = true; adj[v*16+u] = true
		}
		mut dist := []i64{len: 16, init: -1}
		mut queue := []int{len: 16, init: 0}
		dist[0] = 0; mut head := 0; mut tail := 1
		for head < tail {
			u := queue[head]; head++
			for v in 0 .. n {
				if adj[u*16+v] && dist[v] < 0 { dist[v] = dist[u] + 1; queue[tail] = v; tail++ }
			}
		}
		if tail != n { return -1 }
		mut estimate := i64(0)
		for i in 0 .. n { if dist[i] > estimate { estimate = dist[i] } }
		if output == nil || capacity < 8 { return -2 }
		put_i64(mut output, estimate)
		return 8
	}
}
