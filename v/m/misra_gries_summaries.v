@[export: 'misra_gries_summaries']
pub fn misra_gries_summaries(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 66 { return -1 }
		k64 := input[0]
		count64 := input[1]
		if k64 < 1 || k64 > 8 || count64 < 0 || count64 > 64 || length != usize(2+count64) { return -1 }
		k := int(k64)
		count := int(count64)
		mut items := []i64{len: 8, init: -1}
		mut counts := []i64{len: 8, init: 0}
		for index in 0 .. count {
			item := input[index+2]
			if item < 0 || item > 15 { return -1 }
			mut slot := 0
			for slot < k && items[slot] != item { slot++ }
			if slot < k {
				counts[slot]++
			} else {
				slot = 0
				for slot < k && counts[slot] != 0 { slot++ }
				if slot < k {
					items[slot] = item
					counts[slot] = 1
				} else {
					for slot in 0 .. k {
						counts[slot]--
						if counts[slot] == 0 { items[slot] = -1 }
					}
				}
			}
		}
		mut ordered_items := []i64{}
		mut ordered_counts := []i64{}
		for slot in 0 .. k {
			if counts[slot] > 0 {
				mut position := ordered_items.len
				ordered_items << items[slot]
				ordered_counts << counts[slot]
				for position > 0 && ordered_items[position-1] > ordered_items[position] {
					ordered_items[position], ordered_items[position-1] = ordered_items[position-1], ordered_items[position]
					ordered_counts[position], ordered_counts[position-1] = ordered_counts[position-1], ordered_counts[position]
					position--
				}
			}
		}
		used := ordered_items.len
		output_bytes := 8*(1+2*used)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		values := []i64{len: 1+2*used, init: 0}
		values[0] = i64(used)
		for index in 0 .. used {
			values[1+2*index] = ordered_items[index]
			values[2+2*index] = ordered_counts[index]
		}
		for index, value in values {
			bits := u64(value)
			for byte in 0 .. 8 { output[8*index+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
