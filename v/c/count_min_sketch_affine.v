module count_min_sketch_affine

const prime = i64(2147483647)

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'count_min_sketch_affine']
pub fn count_min_sketch_affine(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 59 { return -1 }
	unsafe {
		d64, w64, ops64 := input[0], input[1], input[2]
		if d64 < 1 || d64 > 4 || w64 < 1 || w64 > 8 || ops64 < 0 || ops64 > 16 { return -1 }
		d, w, ops := int(d64), int(w64), int(ops64)
		start := 3 + 2*d
		if length != usize(start+3*ops) { return -1 }
		mut a := [4]i64{}
		mut b := [4]i64{}
		for r in 0 .. d {
			a[r], b[r] = input[3+2*r], input[4+2*r]
			if a[r] < 1 || a[r] >= prime || b[r] < 0 || b[r] >= prime { return -1 }
		}
		mut queries := 0
		for op in 0 .. ops {
			kind, key, weight := input[start+3*op], input[start+3*op+1], input[start+3*op+2]
			if key < 0 || key > 1_000_000 { return -1 }
			if kind == 0 { if weight < 1 || weight > 1_000_000 { return -1 } }
			else if kind == 1 { if weight != 0 { return -1 }; queries++ }
			else { return -1 }
		}
		mut table := [4][8]i64{}
		mut staged := [16]i64{}
		mut count := 0
		for op in 0 .. ops {
			kind, key, weight := input[start+3*op], input[start+3*op+1], input[start+3*op+2]
			mut slots := [4]int{}
			for r in 0 .. d { slots[r] = int(((a[r]*key+b[r]) % prime) % i64(w)) }
			if kind == 0 { for r in 0 .. d { table[r][slots[r]] += weight } }
			else {
				mut minimum := table[0][slots[0]]
				for r in 1 .. d { if table[r][slots[r]] < minimum { minimum = table[r][slots[r]] } }
				staged[count] = minimum; count++
			}
		}
		required := queries*8
		if capacity < usize(required) || (required > 0 && unsafe { output == nil }) { return -2 }
		for i in 0 .. count { put_i64_le(mut output, 8*i, staged[i]) }
		return i64(required)
	}
}
