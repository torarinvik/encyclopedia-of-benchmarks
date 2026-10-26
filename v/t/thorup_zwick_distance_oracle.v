module thorup_zwick_distance_oracle

import core:c

const max_n = 12
const max_m = 66
const max_q = 32
const inf = i64(0x3fffffffffffffff)

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8(bits >> (8*b)) } }
}

@[export: 'thorup_zwick_distance_oracle']
pub fn thorup_zwick_distance_oracle(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > 266 { return -1 }
	unsafe {
		n64, m64, mask := input[0], input[1], input[2]
		if n64 < 1 || n64 > max_n || m64 < 0 || m64 > max_m || mask <= 0 { return -1 }
		n, m := int(n64), int(m64)
		if (u64(mask) >> n) != 0 { return -1 }
		q_at := 3 + 3*m
		if q_at >= int(length) || input[q_at] < 0 || input[q_at] > max_q { return -1 }
		q := int(input[q_at])
		if int(length) != q_at + 1 + 2*q { return -1 }
		mut d := [max_n][max_n]i64{}
		for i in 0 .. n { for j in 0 .. n { d[i][j] = if i == j { i64(0) } else { inf } } }
		for e in 0 .. m {
			u64, v64, w := input[3+3*e], input[4+3*e], input[5+3*e]
			if u64 < 0 || v64 <= u64 || v64 >= n64 || w < 1 || w > 1000 { return -1 }
			u, v := int(u64), int(v64)
			if d[u][v] != inf { return -1 }
			d[u][v], d[v][u] = w, w
		}
		for k in 0 .. n { for i in 0 .. n { for j in 0 .. n {
			if d[i][k] != inf && d[k][j] != inf && d[i][k]+d[k][j] < d[i][j] { d[i][j] = d[i][k]+d[k][j] }
		} } }
		for i in 0 .. n { for j in 0 .. n { if d[i][j] == inf { return -1 } } }
		mut nearest := [max_n]int{}
		mut near_d := [max_n]i64{}
		for v in 0 .. n {
			nearest[v], near_d[v] = -1, inf
			for a in 0 .. n { if ((u64(mask) >> a) & 1) != 0 {
				if d[v][a] < near_d[v] || (d[v][a] == near_d[v] && (nearest[v] < 0 || a < nearest[v])) { nearest[v], near_d[v] = a, d[v][a] }
			} }
		}
		mut bunch := [max_n][max_n]bool{}
		for u in 0 .. n { for x in 0 .. n { bunch[u][x] = ((u64(mask) >> x) & 1) != 0 || d[u][x] < near_d[u] } }
		mut staged := [max_q+1]i64{}
		staged[0] = i64(q)
		for z in 0 .. q {
			a, b := input[q_at+1+2*z], input[q_at+2+2*z]
			if a < 0 || a >= n64 || b < 0 || b >= n64 { return -1 }
			mut u, mut v := int(a), int(b)
			mut found := false
			for level in 0 .. 2 {
				pivot := if level == 0 { v } else { nearest[v] }
				if bunch[u][pivot] { staged[z+1] = d[u][pivot]+d[v][pivot]; found = true; break }
				u, v = v, u
			}
			if !found { return -1 }
		}
		bytes := 8*(q+1)
		if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
		for i in 0 .. q+1 { put_i64(mut output, i*8, staged[i]) }
		return i64(bytes)
	}
}
