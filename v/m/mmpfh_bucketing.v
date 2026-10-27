fn mmpfh_lcp(a i64, b i64) int {
	mut count := 0
	for count < 16 && ((a >> (15-count)) & 1) == ((b >> (15-count)) & 1) { count++ }
	return count
}

fn mmpfh_put_i64(out &u8, pos int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { out[pos+b] = u8((bits >> (8*b)) & 255) } }
}

@[export: 'mmpfh_bucketing']
pub fn mmpfh_bucketing(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 66 { return -1 }
		n0 := input[0]; q0 := input[1]
		if n0 < 1 || n0 > 32 || q0 < 1 || q0 > 32 || length != usize(2+n0+q0) { return -1 }
		n := int(n0); q := int(q0)
		mut keys := []i64{len:n, init:0}; mut queries := []i64{len:q, init:0}
		for i in 0 .. n {
			x := input[2+i]
			if x < 0 || x > 65535 || (i > 0 && keys[i-1] >= x) { return -1 }
			keys[i] = x
		}
		for i in 0 .. q {
			x := input[2+n+i]
			if x < 0 || x > 65535 { return -1 }
			queries[i] = x
			mut found := false
			for j in 0 .. n { if keys[j] == x { found = true } }
			if !found { return -1 }
		}
		buckets := (n+2)/3
		mut d0 := []i64{len:n, init:0}; mut lens := []i64{len:11, init:0}; mut prefixes := []i64{len:11, init:0}; mut ranks := []i64{len:q, init:0}
		for b in 0 .. buckets {
			start := b*3; mut end := start+3; if end > n { end = n }
			mut plen := 16; if end-start > 1 { plen = mmpfh_lcp(keys[start],keys[end-1]) }
			mut prefix := i64(0); if plen > 0 { prefix = keys[start] >> (16-plen) }
			lens[b] = i64(plen); prefixes[b] = prefix
			for i in start .. end { d0[i] = i64(plen) }
		}
		for i in 0 .. q {
			mut pos := 0; for keys[pos] != queries[i] { pos++ }
			plen := int(d0[pos]); mut prefix := i64(0); if plen > 0 { prefix = queries[i] >> (16-plen) }
			mut b := 0; for b < buckets && (lens[b] != i64(plen) || prefixes[b] != prefix) { b++ }
			if b == buckets { return -1 }
			ranks[i] = i64(b*3 + pos-b*3)
		}
		words := 3+n+3*buckets+q
		if output == nil || capacity < usize(words*8) { return -2 }
		mut staged := []i64{len:100, init:0}; mut k := 0
		staged[k] = i64(n); k++; staged[k] = i64(buckets); k++; staged[k] = i64(q); k++
		for i in 0 .. n { staged[k] = d0[i]; k++ }
		for b in 0 .. buckets { staged[k] = lens[b]; k++; staged[k] = prefixes[b]; k++; staged[k] = i64(b); k++ }
		for i in 0 .. q { staged[k] = ranks[i]; k++ }
		for i in 0 .. words { mmpfh_put_i64(output,i*8,staged[i]) }
		return i64(words*8)
	}
}
