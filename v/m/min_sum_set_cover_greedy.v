@[export: 'min_sum_set_cover_greedy']
pub fn min_sum_set_cover_greedy(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 18 { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 1 || n64 > 12 || m64 < 1 || m64 > 16 || length != usize(2+m64) { return -1 }
		n, m := int(n64), int(m64)
		mut masks := []u64{len: m, init: 0}
		for set in 0 .. m {
			raw := input[2+set]
			if raw <= 0 || u64(raw) >= (u64(1)<<n) { return -1 }
			masks[set] = u64(raw)
		}
		output_bytes := 8*(n+1)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut covered := []bool{len: m, init: false}
		mut used := []bool{len: n, init: false}
		mut order := []i64{len: n, init: 0}
		mut total_time := i64(0)
		for slot in 1 .. n+1 {
			mut chosen := 0
			mut best_count := -1
			for element in 0 .. n {
				if used[element] { continue }
				mut count := 0
				for set in 0 .. m {
					if !covered[set] && (masks[set] & (u64(1)<<element)) != 0 { count++ }
				}
				if count > best_count { best_count, chosen = count, element }
			}
			used[chosen] = true
			order[slot-1] = i64(chosen)
			for set in 0 .. m {
				if !covered[set] && (masks[set] & (u64(1)<<chosen)) != 0 {
					covered[set] = true
					total_time += i64(slot)
				}
			}
		}
		values := []i64{len: n+1, init: 0}
		values[0] = total_time
		for i in 0 .. n { values[i+1] = order[i] }
		for index, value in values {
			bits := u64(value)
			for byte in 0 .. 8 { output[8*index+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
