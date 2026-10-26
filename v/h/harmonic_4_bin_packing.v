@[export: 'harmonic_4_bin_packing']
pub fn harmonic_4_bin_packing(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 33 { return -1 }
		n64 := input[0]
		if n64 < 1 || n64 > 32 || length != usize(1+n64) { return -1 }
		n := int(n64)
		for i in 0 .. n { if input[1+i] < 1 || input[1+i] > 10000 { return -1 } }
		output_bytes := 8*(n+1)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut current := []i64{len: 4, init: -1}
		mut remaining := []i64{len: 4, init: 0}
		mut assignment := []i64{len: n, init: 0}
		mut bins := i64(0)
		for i in 0 .. n {
			size := input[1+i]
			kind := if size*2 > 10000 { 0 } else if size*3 > 10000 { 1 } else if size*4 > 10000 { 2 } else { 3 }
			if current[kind] < 0 || size > remaining[kind] {
				current[kind] = bins
				bins++
				remaining[kind] = 10000
			}
			assignment[i] = current[kind]
			remaining[kind] -= size
		}
		values := []i64{len: n+1, init: 0}
		values[0] = bins
		for i in 0 .. n { values[i+1] = assignment[i] }
		for index, value in values {
			bits := u64(value)
			for byte in 0 .. 8 { output[8*index+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
