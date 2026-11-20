module two_left_hashing_operation_trace

fn store_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8((bits >> (8*b)) & 255) } }
}

@[export: 'two_left_hashing_operation_trace']
pub fn two_left_hashing_operation_trace(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > 162 { return -1 }
	qraw := unsafe { input[0] }
	if qraw < 1 || qraw > 40 || int(length) != 1 + 4*int(qraw) { return -1 }
	q := int(qraw)
	for i in 0 .. q {
		op := unsafe { input[1+4*i] }; key := unsafe { input[2+4*i] }
		left := unsafe { input[3+4*i] }; right := unsafe { input[4+4*i] }
		if op < 0 || op > 2 || key < 0 || key > 63 || left < 0 || left > 7 || right < 0 || right > 7 { return -1 }
		for j in 0 .. i { if unsafe { input[2+4*j] == key && (input[3+4*j] != left || input[4+4*j] != right) } { return -1 } }
	}
	bytes := 16*q
	if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
	mut heads := [16]int{}; mut sizes := [16]int{}
	mut keys := [32]i64{}; mut next := [32]int{}
	mut statuses := [40]i64{}; mut places := [40]i64{}
	for b in 0 .. 16 { heads[b] = -1 }
	for x in 0 .. 32 { keys[x] = -1; next[x] = -1 }
	mut live := 0
	for i in 0 .. q {
		op := int(unsafe { input[1+4*i] }); key := unsafe { input[2+4*i] }
		lb := int(unsafe { input[3+4*i] }); rb := 8 + int(unsafe { input[4+4*i] })
		mut found := -1; mut fb := -1
		for side in 0 .. 2 {
			bucket := if side == 0 { lb } else { rb }; mut x := heads[bucket]
			for x >= 0 { if keys[x] == key { found=x; fb=bucket; break }; x=next[x] }
			if found >= 0 { break }
		}
		if op == 0 {
			if found >= 0 { statuses[i]=0; places[i]= -1; continue }
			if live == 32 { return -3 }
			use_left := sizes[lb] <= sizes[rb]; bucket := if use_left { lb } else { rb }
			mut node := 0; for keys[node] >= 0 { node++ }
			keys[node]=key; next[node]=heads[bucket]; heads[bucket]=node; sizes[bucket]++; live++
			statuses[i]=1; places[i]=if use_left { 0 } else { 1 }
		} else if op == 1 { statuses[i]=if found >= 0 { 1 } else { 0 }; places[i]= -1
		} else if found < 0 { statuses[i]=0; places[i]= -1
		} else {
			mut prev := -1; mut x := heads[fb]
			for x != found { prev=x; x=next[x] }
			if prev < 0 { heads[fb]=next[x] } else { next[prev]=next[x] }
			keys[x]= -1; next[x]= -1; sizes[fb]--; live--; statuses[i]=1; places[i]= -1
		}
	}
	for i in 0 .. q { store_le(mut output,16*i,statuses[i]); store_le(mut output,16*i+8,places[i]) }
	return i64(bytes)
}
