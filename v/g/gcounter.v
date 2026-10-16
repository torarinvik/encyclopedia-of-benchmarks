fn hash_value(h0 u64, value i64) u64 {
	mut h := h0
	bits := u64(value)
	for i in 0 .. 8 { h = (h ^ ((bits >> (8 * i)) & 255)) * u64(0x100000001b3) }
	return h
}
@[export: 'gcounter']
pub fn gcounter(a &i64, n usize) i64 {
	if isnil(a) || n < 2 || n > 386 { return -1 }
	unsafe {
		if a[0] < 1 || a[0] > 8 || a[1] < 0 || a[1] > 128 || n != usize(2 + 3 * a[1]) { return -1 }
		nodes := int(a[0])
		mut s := []i64{len:64,init:0}
		mut h := u64(0xcbf29ce484222325)
		for i in 0 .. int(a[1]) {
			op := a[2+3*i]; aa := a[3+3*i]; bb := a[4+3*i]
			if aa < 0 || aa >= i64(nodes) { return -1 }
			ai := int(aa)
			if op == 0 {
				if bb != 0 || s[ai*8+ai] >= 1000000 { return -1 }
				s[ai*8+ai]++
			} else if op == 1 {
				if bb != 0 { return -1 }
				mut total := i64(0)
				for j in 0 .. nodes { total += s[ai*8+j] }
				h = hash_value(h,total)
			} else if op == 2 {
				if bb < 0 || bb >= i64(nodes) { return -1 }
				bi := int(bb); mut yes := true
				for j in 0 .. nodes { if s[ai*8+j] > s[bi*8+j] { yes = false } }
				if yes { h=hash_value(h,1) } else { h=hash_value(h,0) }
			} else if op == 3 {
				if bb < 0 || bb >= i64(nodes) { return -1 }
				bi := int(bb)
				for j in 0 .. nodes { if s[bi*8+j] > s[ai*8+j] { s[ai*8+j]=s[bi*8+j] } }
			} else { return -1 }
		}
		for i in 0 .. nodes { for j in 0 .. nodes { h=hash_value(h,s[i*8+j]) } }
		return i64(h)
	}
}
