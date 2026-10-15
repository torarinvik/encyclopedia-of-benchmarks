module association

fn popcount(value_in u32) int {
	mut value := value_in
	mut count := 0
	for value != 0 { count += int(value & 1); value >>= 1 }
	return count
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'association']
pub fn association(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 11 { return -1 }
		transactions, items := int(input[0]), int(input[1])
		if length != usize(2+transactions) { return -1 }
		limit := 1 << items
		valid_bits := i64(limit-1)
		for t in 0 .. transactions { if input[2+t] < 0 || input[2+t] > valid_bits { return -1 } }
		mut frequent := [2048]bool{init: false}
		mut masks := [2047]i64{init: 0}
		mut supports := [2047]i64{init: 0}
		mut count := 0
		for set_size in 1 .. items+1 {
			for mask in 1 .. limit {
				if popcount(u32(mask)) != set_size { continue }
				if set_size > 1 {
					mut ok := true
					for bit in 0 .. items { bit_mask := 1 << bit; if mask & bit_mask != 0 && !frequent[mask ^ bit_mask] { ok = false } }
					if !ok { continue }
				}
				mut support := i64(0)
				for t in 0 .. transactions { if (int(input[2+t]) & mask) == mask { support++ } }
				if support > 0 { frequent[mask] = true; masks[count] = i64(mask); supports[count] = support; count++ }
			}
		}
		required := count*16
		if capacity < usize(required) || (required > 0 && unsafe { output == nil }) { return -2 }
		for i in 0 .. count { put_i64_le(mut output,i*16,masks[i]); put_i64_le(mut output,i*16+8,supports[i]) }
		return i64(required)
	}
}
