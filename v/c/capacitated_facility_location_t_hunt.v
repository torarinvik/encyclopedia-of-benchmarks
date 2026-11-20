const max_n = 4
const max_f = 3
const max_q = 4
const max_p = 7
const neg_inf = i64(-2305843009213693952)

fn put_word(mut output []u8, at int, value i64) {
	mut bits := u64(value)
	for b in 0 .. 8 { output[at+b] = u8(bits & 255); bits >>= 8 }
}

@[export: 'capacitated_facility_location_t_hunt']
pub fn capacitated_facility_location_t_hunt(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 68 { return -1 }
		nr, fr, qr, tr := input[0], input[1], input[2], input[3]
		if nr < 1 || nr > max_n || fr < 1 || fr > max_f || qr < 1 || qr > max_q || tr < 0 || tr >= fr { return -1 }
		n, f, q, target := int(nr), int(fr), int(qr), int(tr)
		points := n + f
		if length != usize(4 + points*points + 2*f + q + n) { return -1 }
		mut d := [][]i64{len: max_p, init: []i64{len: max_p}}
		mut fee := []i64{len: max_f}
		mut caps := []i64{len: max_f}
		mut kind := []int{len: max_q}
		mut assigned := []int{len: max_n}
		mut at := 4
		for i in 0 .. points {
			for j in 0 .. points {
				v := input[at]; at++
				if v < 0 || v > 1000 { return -1 }
				d[i][j] = v
			}
		}
		for i in 0 .. points {
			if d[i][i] != 0 { return -1 }
			for j in 0 .. points {
				if i != j && d[i][j] == 0 { return -1 }
				if d[i][j] != d[j][i] { return -1 }
				for k in 0 .. points { if d[i][j] > d[i][k]+d[k][j] { return -1 } }
			}
		}
		for i in 0 .. f { fee[i] = input[at]; at++; if fee[i] < 0 || fee[i] > 1000 { return -1 } }
		for i in 0 .. f { caps[i] = input[at]; at++; if caps[i] < 1 || caps[i] > nr { return -1 } }
		for i in 0 .. q { v := input[at]; at++; if v < 0 || v >= fr { return -1 }; kind[i] = int(v) }
		for i in 0 .. n { v := input[at]; at++; if v < 0 || v >= qr { return -1 }; assigned[i] = int(v) }
		mut weight := []i64{len: max_q}
		mut profit := []i64{len: max_q}
		mut old := i64(0)
		for c in 0 .. q { profit[c] = fee[kind[c]]; old += fee[kind[c]] }
		for u in 0 .. n {
			c := assigned[u]; source := kind[c]; weight[c]++
			if weight[c] > caps[source] { return -1 }
			before, after := d[u][n+source], d[u][n+target]
			old += before; profit[c] -= after-before
		}
		mut result := [5]i64{init: 0}
		result[3], result[4] = old, old
		for copies in 1 .. n+1 {
			mut limit := copies*int(caps[target]); if limit > n { limit = n }
			mut dp := []i64{len: max_n+1, init: neg_inf}
			mut masks := []u32{len: max_n+1}
			dp[0] = 0
			for item in 0 .. q {
				mut next := dp.clone(); mut next_masks := masks.clone(); iw := int(weight[item])
				if iw <= limit {
					for w in 0 .. limit-iw+1 {
						if dp[w] != neg_inf {
							nw := w+iw; value := dp[w]+profit[item]; mask := masks[w] | (u32(1)<<u32(item))
							if value > next[nw] || (value == next[nw] && mask < next_masks[nw]) { next[nw] = value; next_masks[nw] = mask }
						}
					}
				}
				dp, masks = next, next_masks
			}
			mut best := neg_inf; mut best_mask := u32(0)
			for w in 0 .. limit+1 { if dp[w] > best || (dp[w] == best && masks[w] < best_mask) { best = dp[w]; best_mask = masks[w] } }
			if best > i64(copies)*fee[target] { result = [i64(1),i64(copies),i64(best_mask),old,old+i64(copies)*fee[target]-best]; break }
		}
		if output == nil || capacity < 40 { return -2 }
		mut staged := []u8{len: 40}
		for i in 0 .. 5 { put_word(mut staged,8*i,result[i]) }
		for i in 0 .. 40 { output[i] = staged[i] }
		return 40
	}
}
