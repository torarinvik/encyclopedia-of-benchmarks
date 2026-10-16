module fifocache

@[export: 'fifocache']
pub fn fifocache(a &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 2 || length > 26 { return -1 }
	unsafe {
		if a == nil { return -1 }
		cap := a[0]
		ops := a[1]
		if cap < 1 || cap > 6 || ops < 0 || ops > 8 || length != usize(2 + 3 * ops) { return -1 }
		mut keys := [6]i64{}
		mut vals := [6]i64{}
		mut queries := [8]u8{}
		mut size := 0
		mut gets := 0
		mut hits := u8(0)
		mut misses := u8(0)
		for i in 0 .. int(ops) {
			op := a[2 + 3 * i]
			key := a[3 + 3 * i]
			value := a[4 + 3 * i]
			if key < 0 || key > 15 || (op != 0 && op != 1) { return -1 }
			if op == 0 {
				if value < 0 || value > 255 { return -1 }
				mut j := 0
				for j < size && keys[j] != key { j++ }
				if j < size {
					for t := j + 1; t < size; t++ { keys[t - 1] = keys[t]; vals[t - 1] = vals[t] }
					size--
				}
				if size == int(cap) {
					for t := 1; t < size; t++ { keys[t - 1] = keys[t]; vals[t - 1] = vals[t] }
					size--
				}
				keys[size] = key
				vals[size] = value
				size++
			} else {
				if value != 0 { return -1 }
				mut j := 0
				for j < size && keys[j] != key { j++ }
				if j < size { hits++; queries[gets] = u8(vals[j]) }
				else { misses++; queries[gets] = 255 }
				gets++
			}
		}
		need := 4 + gets + 2 * size
		if output == nil || capacity < usize(need) { return -2 }
		output[0] = hits; output[1] = misses; output[2] = u8(size); output[3] = u8(gets)
		for i in 0 .. gets { output[4 + i] = queries[i] }
		for i in 0 .. size { output[4 + gets + 2 * i] = u8(keys[i]); output[5 + gets + 2 * i] = u8(vals[i]) }
		return i64(need)
	}
}
