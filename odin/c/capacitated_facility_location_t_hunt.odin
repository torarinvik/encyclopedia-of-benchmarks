package capacitated_facility_location_t_hunt

import "core:c"

MAX_N :: 4
MAX_F :: 3
MAX_Q :: 4
MAX_P :: 7
NEG_INF :: i64(-2305843009213693952)

put_word :: proc "contextless" (out: [^]u8, at: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 {
		out[at+b] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
capacitated_facility_location_t_hunt :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 68 do return -1
	nr, fr, qr, tr := input[0], input[1], input[2], input[3]
	if nr < 1 || nr > MAX_N || fr < 1 || fr > MAX_F || qr < 1 || qr > MAX_Q || tr < 0 || tr >= fr do return -1
	n, f, q, target := int(nr), int(fr), int(qr), int(tr)
	points := n + f
	if length != c.size_t(4 + points*points + 2*f + q + n) do return -1
	d: [MAX_P][MAX_P]i64
	fee: [MAX_F]i64
	caps: [MAX_F]i64
	kind: [MAX_Q]int
	assigned: [MAX_N]int
	at := 4
	for i := 0; i < points; i += 1 {
		for j := 0; j < points; j += 1 {
			v := input[at]; at += 1
			if v < 0 || v > 1000 do return -1
		d[i][j] = v
		}
	}
	for i := 0; i < points; i += 1 {
		if d[i][i] != 0 do return -1
		for j := 0; j < points; j += 1 {
			if i != j && d[i][j] == 0 do return -1
			if d[i][j] != d[j][i] do return -1
			for k := 0; k < points; k += 1 do if d[i][j] > d[i][k]+d[k][j] do return -1
		}
	}
	for i := 0; i < f; i += 1 { fee[i] = input[at]; at += 1; if fee[i] < 0 || fee[i] > 1000 do return -1 }
	for i := 0; i < f; i += 1 { caps[i] = input[at]; at += 1; if caps[i] < 1 || caps[i] > nr do return -1 }
	for i := 0; i < q; i += 1 { v := input[at]; at += 1; if v < 0 || v >= fr do return -1; kind[i] = int(v) }
	for i := 0; i < n; i += 1 { v := input[at]; at += 1; if v < 0 || v >= qr do return -1; assigned[i] = int(v) }
	weight: [MAX_Q]i64
	profit: [MAX_Q]i64
	old := i64(0)
	for c := 0; c < q; c += 1 { profit[c] = fee[kind[c]]; old += fee[kind[c]] }
	for u := 0; u < n; u += 1 {
		c := assigned[u]; source := kind[c]; weight[c] += 1
		if weight[c] > caps[source] do return -1
		before, after := d[u][n+source], d[u][n+target]
		old += before; profit[c] -= after-before
	}
	result := [5]i64{0,0,0,old,old}
	for copies := 1; copies <= n; copies += 1 {
		limit := copies*int(caps[target]); if limit > n do limit = n
		dp: [MAX_N+1]i64; masks: [MAX_N+1]u32
		for w := 0; w <= limit; w += 1 do dp[w] = NEG_INF
		dp[0] = 0
		for item := 0; item < q; item += 1 {
			next, next_masks := dp, masks
			iw := int(weight[item])
			if iw <= limit {
				for w := 0; w+iw <= limit; w += 1 {
					if dp[w] != NEG_INF {
						nw := w+iw; value := dp[w]+profit[item]; mask := masks[w] | (u32(1)<<u32(item))
						if value > next[nw] || (value == next[nw] && mask < next_masks[nw]) { next[nw] = value; next_masks[nw] = mask }
					}
				}
			}
			dp, masks = next, next_masks
		}
		best := NEG_INF; best_mask := u32(0)
		for w := 0; w <= limit; w += 1 { if dp[w] > best || (dp[w] == best && masks[w] < best_mask) { best = dp[w]; best_mask = masks[w] } }
		if best > i64(copies)*fee[target] { result = [5]i64{1,i64(copies),i64(best_mask),old,old+i64(copies)*fee[target]-best}; break }
	}
	if output == nil || capacity < 40 do return -2
	for i := 0; i < 5; i += 1 do put_word(output, 8*i, result[i])
	return 40
}
