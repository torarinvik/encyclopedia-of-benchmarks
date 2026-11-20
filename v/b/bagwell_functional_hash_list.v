const Starts = [3]int{0, 8, 24}
const Sides = [3]int{8, 16, 32}

fn put_i64_le(mut output &u8, at int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[at + b] = u8((bits >> (b * 8)) & 255) } }
}

@[export: 'bagwell_functional_hash_list']
pub fn bagwell_functional_hash_list(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if isnil(input) || length < 2 || length > 131 { return -1 }
	nv := unsafe { input[0] }
	if nv < 0 || nv > 32 { return -1 }
	n := int(nv)
	q_at := 1 + 2*n
	if q_at >= int(length) { return -1 }
	qv := unsafe { input[q_at] }
	if qv < 1 || qv > 32 { return -1 }
	q := int(qv)
	query_at := q_at + 1
	if int(length) != 2 + 2*n + 2*q { return -1 }
	for i in 0 .. n {
		key := unsafe { input[1+2*i] }
		value := unsafe { input[2+2*i] }
		if key < -2147483648 || key > 2147483647 || value < -2147483648 || value > 2147483647 { return -1 }
	}
	for j in 0 .. q {
		root := unsafe { input[query_at+2*j] }
		key := unsafe { input[query_at+2*j+1] }
		if root < 0 || root > nv || key < -2147483648 || key > 2147483647 { return -1 }
	}
	output_bytes := 8*q
	if isnil(output) || capacity < usize(output_bytes) { return -2 }

	mut keys := [56]i64{}
	mut values := [56]i64{}
	mut next := [56]int{init: -1}
	mut heads := [56]int{init: -1}
	mut prev := [3]int{init: -1}
	mut root_block := [33]int{init: -1}
	mut root_offset := [33]int{init: -1}
	mut current := 0
	for i in 0 .. n {
		if i == 8 || i == 24 { prev[current+1] = current; current++ }
		start := Starts[current]
		side := Sides[current]
		offset := i - start
		slot := start + offset
		hash := u32(unsafe { input[1+2*i] })
		bucket_slot := start + int(hash & u32(side-1))
		keys[slot] = unsafe { input[1+2*i] }
		values[slot] = unsafe { input[2+2*i] }
		next[slot] = heads[bucket_slot]
		heads[bucket_slot] = offset
		root_block[i+1] = current
		root_offset[i+1] = offset
	}
	for j in 0 .. q {
		root := int(unsafe { input[query_at+2*j] })
		key := unsafe { input[query_at+2*j+1] }
		mut block := root_block[root]
		limit := root_offset[root]
		mut answer := i64(-9223372036854775807) - 1
		if block >= 0 {
			hash := u32(key)
			mut first := true
			for block >= 0 && answer == i64(-9223372036854775807)-1 {
				start := Starts[block]
				side := Sides[block]
				bucket_slot := start + int(hash & u32(side-1))
				mut chain := heads[bucket_slot]
				for chain >= 0 {
					slot := start + chain
					if (!first || chain <= limit) && keys[slot] == key { answer = values[slot]; break }
					chain = next[slot]
				}
				block = prev[block]
				first = false
			}
		}
		put_i64_le(mut output, 8*j, answer)
	}
	return i64(output_bytes)
}
