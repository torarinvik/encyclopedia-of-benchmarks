@[export: 'generic_hash_map']
pub fn generic_hash_map(a &i64, n usize) i64 {
	if isnil(a) || n < 1 || n > 385 { return -1 }
	unsafe {
		if a[0] < 0 || a[0] > 128 || n != usize(1 + 3 * a[0]) { return -1 }
		mut keys := []i64{len:64,init:0}
		mut vals := []i64{len:64,init:0}
		mut next := []int{len:64,init:-1}
		mut head := []int{len:128,init:-1}
		mut active := []bool{len:64,init:false}
		mut size := 0
		mut bc := 16
		mut h := u64(0xcbf29ce484222325)
		for oi in 0 .. int(a[0]) {
			op := a[1+3*oi]; key := a[2+3*oi]; value := a[3+3*oi]
			if key < 0 || key > 1000000 { return -1 }
			mut b := int(key % i64(bc)); mut found := -1; mut j := head[b]
			for j >= 0 { if keys[j] == key { found = j; break }; j = next[j] }
			if op == 0 {
				if value < -1000000 || value > 1000000 { return -1 }
				if found >= 0 { vals[found] = value } else {
					if size >= 64 { return -1 }
					mut slot := 0; for active[slot] { slot++ }
					active[slot] = true; keys[slot] = key; vals[slot] = value; next[slot] = head[b]; head[b] = slot; size++
					if size*4 > bc*3 && bc < 128 { bc *= 2; for i in 0 .. 128 { head[i] = -1 }; for q in 0 .. 64 { if active[q] { b = int(keys[q] % i64(bc)); next[q] = head[b]; head[b] = q } } }
				}
			} else if op == 1 || op == 3 {
				if value != 0 { return -1 }
				mut observed := i64(0)
				if op == 1 { observed = i64(-9223372036854775808); if found >= 0 { observed = vals[found] } } else if found >= 0 { observed = 1 }
				h = hash_value(h, observed)
			} else if op == 2 {
				if value != 0 { return -1 }
				if found >= 0 { mut prev := -1; j = head[b]; for j >= 0 { if j == found { if prev < 0 { head[b] = next[j] } else { next[prev] = next[j] }; break }; prev = j; j = next[j] }; active[found] = false; size-- }
			} else if op == 4 { if key != 0 || value != 0 { return -1 }; h = hash_value(h, i64(size)) } else { return -1 }
		}
		h = hash_value(h, i64(size)); mut used := []bool{len:64,init:false}
		for _ in 0 .. size { mut best := -1; for i in 0 .. 64 { if active[i] && !used[i] && (best < 0 || keys[i] < keys[best]) { best = i } }; used[best] = true; h = hash_value(hash_value(h, keys[best]), vals[best]) }
		return i64(h)
	}
}

fn hash_value(h0 u64, value i64) u64 {
	mut h := h0
	bits := u64(value)
	for i in 0 .. 8 { h = (h ^ ((bits >> (8*i)) & 255)) * u64(0x100000001b3) }
	return h
}
