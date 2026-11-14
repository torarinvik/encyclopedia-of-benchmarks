// Uncompiled bounded GF(2) quadratic normal-form draft.
module quadratic_form_gf2_normal_form

struct QfVec {
mut:
	lo u64
	hi u64
}

fn qf_xor(a QfVec, b QfVec) QfVec { return QfVec{lo: a.lo ^ b.lo, hi: a.hi ^ b.hi} }
fn qf_bit(v QfVec, i int) bool {
	if i < 64 { return ((v.lo >> i) & 1) != 0 }
	return ((v.hi >> (i - 64)) & 1) != 0
}
fn qf_set(mut v QfVec, i int) {
	if i < 64 { v.lo |= u64(1) << i } else { v.hi |= u64(1) << (i - 64) }
}
fn qf_parity(value u64) int {
	mut x := value
	x ^= x >> 32; x ^= x >> 16; x ^= x >> 8
	x ^= x >> 4; x ^= x >> 2; x ^= x >> 1
	return int(x & 1)
}
fn qf_apply(rows &[100]QfVec, n int, a QfVec, b QfVec) int {
	mut result := 0
	for i in 0 .. n {
		if qf_bit(a, i) { result ^= qf_parity((rows[i].lo & b.lo) ^ (rows[i].hi & b.hi)) }
	}
	return result
}

@[export: 'quadratic_form_gf2_normal_form']
pub fn quadratic_form_gf2_normal_form(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length == 0 || length > 202 || input[0] < 1 || input[0] > 100 { return -1 }
		n := int(input[0])
		words := (n + 62) / 63
		if length != usize(1 + n * words) { return -1 }
		mut upper := [100]QfVec{}
		mut bilinear := [100]QfVec{}
		for i in 0 .. n {
			for chunk in 0 .. words {
				raw := input[1 + i * words + chunk]
				if raw < 0 { return -1 }
				for b in 0 .. 63 {
					if ((u64(raw) >> b) & 1) == 0 { continue }
					j := 63 * chunk + b
					if j >= n || j < i { return -1 }
					qf_set(mut upper[i], j)
					if i != j { qf_set(mut bilinear[i], j); qf_set(mut bilinear[j], i) }
				}
			}
		}
		row_bytes := (n + 7) / 8
		needed := 3 + n * row_bytes
		if output == nil || capacity < usize(needed) { return -2 }
		mut remaining := [100]QfVec{}
		mut hyper := [100]QfVec{}
		mut anis := [100]QfVec{}
		mut columns := [100]QfVec{}
		for i in 0 .. n { qf_set(mut remaining[i], i) }
		mut count := n
		mut hc := 0
		mut ac := 0
		for {
			mut left := count
			mut right := count
			for i in 0 .. count {
				for j in i + 1 .. count {
					if qf_apply(&bilinear, n, remaining[i], remaining[j]) != 0 { left = i; right = j; break }
				}
				if left != count { break }
			}
			if left == count { break }
			mut u := remaining[left]
			mut v := remaining[right]
			mut rest := [100]QfVec{}
			mut next := 0
			for i in 0 .. count {
				if i == left || i == right { continue }
				mut w := remaining[i]
				if qf_apply(&bilinear, n, remaining[i], v) != 0 { w = qf_xor(w, u) }
				if qf_apply(&bilinear, n, remaining[i], u) != 0 { w = qf_xor(w, v) }
				rest[next] = w; next++
			}
			remaining = rest; count = next
			qu := qf_apply(&upper, n, u, u)
			qv := qf_apply(&upper, n, v, v)
			if qu != 0 && qv != 0 { anis[ac] = u; anis[ac + 1] = v; ac += 2 }
			else {
				if qu != 0 { u = qf_xor(u, v) } else if qv != 0 { v = qf_xor(v, u) }
				hyper[hc] = u; hyper[hc + 1] = v; hc += 2
			}
		}
		for ac >= 4 {
			a := anis[ac - 2]; b := anis[ac - 1]; c := anis[ac - 4]; d := anis[ac - 3]
			ac -= 4
			f := qf_xor(d, qf_xor(a, b))
			hyper[hc] = qf_xor(a, c); hyper[hc + 1] = qf_xor(b, c)
			hyper[hc + 2] = f; hyper[hc + 3] = qf_xor(f, c); hc += 4
		}
		mut linear := QfVec{}
		mut has_linear := false
		for i in 0 .. count {
			if qf_apply(&upper, n, remaining[i], remaining[i]) == 0 { continue }
			linear = remaining[i]; has_linear = true
			for j in i + 1 .. count { remaining[j - 1] = remaining[j] }
			count--; break
		}
		if has_linear {
			for i in 0 .. count {
				if qf_apply(&upper, n, remaining[i], remaining[i]) != 0 { remaining[i] = qf_xor(remaining[i], linear) }
			}
			if ac != 0 {
				hyper[hc] = qf_xor(anis[0], linear); hyper[hc + 1] = qf_xor(anis[1], linear)
				hc += 2; ac = 0
			}
		}
		mut used := 0
		for i in 0 .. hc { columns[used] = hyper[i]; used++ }
		for i in 0 .. ac { columns[used] = anis[i]; used++ }
		if has_linear { columns[used] = linear; used++ }
		for i in 0 .. count { columns[used] = remaining[i]; used++ }
		if used != n || hc % 2 != 0 || (ac != 0 && ac != 2) { return -4 }
		mut matrix := [100]QfVec{}
		mut inverse := [100]QfVec{}
		for i in 0 .. n {
			qf_set(mut inverse[i], i)
			for j in 0 .. n { if qf_bit(columns[j], i) { qf_set(mut matrix[i], j) } }
		}
		for col in 0 .. n {
			mut pivot := col
			for pivot < n && !qf_bit(matrix[pivot], col) { pivot++ }
			if pivot == n { return -4 }
			matrix[col], matrix[pivot] = matrix[pivot], matrix[col]
			inverse[col], inverse[pivot] = inverse[pivot], inverse[col]
			for row in 0 .. n {
				if row != col && qf_bit(matrix[row], col) {
					matrix[row] = qf_xor(matrix[row], matrix[col]); inverse[row] = qf_xor(inverse[row], inverse[col])
				}
			}
		}
		mut staged := [1303]u8{}
		staged[0] = u8(hc / 2); staged[1] = u8(ac / 2)
		if has_linear { staged[2] = 1 }
		for i in 0 .. n {
			for j in 0 .. n {
				if qf_bit(inverse[i], j) { staged[3 + i * row_bytes + j / 8] |= u8(1 << (j % 8)) }
			}
		}
		for i in 0 .. needed { output[i] = staged[i] }
		return i64(needed)
	}
}
