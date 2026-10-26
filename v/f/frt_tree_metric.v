module frt_tree_metric

fn within(d i64, beta i64, level int) bool {
	if level >= 0 { return d * 1024 <= beta * (i64(1) << level) }
	return d * 1024 * (i64(1) << -level) <= beta
}
fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8((bits >> u64(8*b)) & 255) } }
}

@[export: 'frt_tree_metric']
pub fn frt_tree_metric(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 8 || length > 74 { return -1 }
	unsafe {
		n0, beta := input[0], input[1]
		if n0 < 2 || n0 > 8 || beta < 1024 || beta > 2047 { return -1 }
		n := int(n0)
		if length != usize(2+n+n*n) { return -1 }
		mut perm := []int{len: 8, init: 0}; mut seen := []bool{len: 8, init: false}
		for i in 0 .. n {
			p := input[2+i]
			if p < 0 || p >= n0 || seen[int(p)] { return -1 }
			seen[int(p)] = true; perm[i] = int(p)
		}
		mut d := []i64{len: 64, init: 0}; mut maxd := i64(0); base := 2+n
		for i in 0 .. n { for j in 0 .. n {
			x := input[base+i*n+j]
			if x < 0 || x > 255 || (i == j && x != 0) || (i != j && x == 0) { return -1 }
			d[i*n+j] = x; if x > maxd { maxd = x }
		} }
		for i in 0 .. n { for j in 0 .. n {
			if d[i*n+j] != d[j*n+i] { return -1 }
			for k in 0 .. n { if d[i*n+j] > d[i*n+k]+d[k*n+j] { return -1 } }
		} }
		mut high := 0; for (i64(1) << high) < maxd { high++ }
		mut staged := []i64{len: 64, init: 0}; mut clusters := []u16{len: 256, init: 0}; mut next := []u16{len: 256, init: 0}
		mut count := 1; clusters[0] = u16((1 << n)-1)
		for level := high; level >= -10; level-- {
			mut next_count := 0; td := i64(1) << (level+13)
			for ci in 0 .. count {
				mut remaining := clusters[ci]; mut done := u16(0)
				for remaining != 0 {
					mut center := n
					for p in 0 .. n { if (remaining & (u16(1) << perm[p])) != 0 { center = perm[p]; break } }
					if center == n { return -1 }
					mut child := u16(0)
					for v in 0 .. n { if (remaining & (u16(1) << v)) != 0 && within(d[center*n+v], beta, level) { child |= u16(1) << v } }
					if child == 0 { child = u16(1) << center }
					for u in 0 .. n { if (done & (u16(1) << u)) != 0 { for v in 0 .. n { if (child & (u16(1) << v)) != 0 { staged[u*n+v] = td; staged[v*n+u] = td } } } }
					done |= child; remaining &= ~child; next[next_count] = child; next_count++
				}
			}
			for i in 0 .. next_count { clusters[i] = next[i] }; count = next_count
		}
		bytes := usize(8*n*n)
		if output == nil || capacity < bytes { return -2 }
		for i in 0 .. n*n { put_i64(mut output, i*8, staged[i]) }
		return i64(bytes)
	}
}
