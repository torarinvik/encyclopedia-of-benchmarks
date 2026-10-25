module versabench_dbms_keys_union

fn write_i64_le(output &u8, index int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[index * 8 + b] = u8((bits >> u64(8 * b)) & 255) } }
}

@[export: 'versabench_dbms_keys_union']
pub fn versabench_dbms_keys_union(input &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 130 { return -1 }
		raw_count := input[0]
		if raw_count < 1 || raw_count > 16 || length != usize(1 + 8 * int(raw_count)) { return -1 }
		mut bounds := [8]i64{}
		for d in 0 .. 4 { bounds[d] = input[1+d]; bounds[4+d] = input[5+d] }
		for i in 0 .. int(raw_count) {
			at := 1 + 8 * i
			for d in 0 .. 4 {
				lo := input[at+d]; hi := input[at+4+d]
				if lo < -8 || lo > 8 || hi < -8 || hi > 8 || lo > hi { return -1 }
				if lo < bounds[d] { bounds[d] = lo }; if hi > bounds[4+d] { bounds[4+d] = hi }
			}
		}
		if output == nil || output_capacity < 64 { return -2 }
		for i in 0 .. 8 { write_i64_le(output, i, bounds[i]) }
		return 64
	}
}
