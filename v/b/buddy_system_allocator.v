module buddy_system_allocator

const arena = 256
const max_order = 8
const max_ops = 64
const max_ids = 32
const max_input_words = 194
const max_output_words = 3 * max_ops + 1 + 2 * arena

@[export: 'buddy_system_allocator']
pub fn buddy_system_allocator(values &i64, length usize, output &mut u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > max_input_words { return -1 }
		raw_count := values[0]
		if raw_count < 0 || raw_count > max_ops || length != usize(1 + 3 * raw_count) { return -1 }
		count := int(raw_count)
		mut free_blocks := [max_order + 1][arena]bool{init: false}
		mut active := [max_ids]bool{init: false}
		mut allocation_base := [max_ids]int{init: 0}
		mut allocation_order := [max_ids]int{init: 0}
		mut staged := [max_output_words]i64{init: 0}
		free_blocks[max_order][0] = true
		mut staged_words := 0
		for i in 0 .. count {
			opcode := values[1 + 3 * i]
			raw_id := values[2 + 3 * i]
			argument := values[3 + 3 * i]
			if raw_id < 0 || raw_id >= max_ids { return -1 }
			id := int(raw_id)
			if opcode == 0 {
				if argument < 1 || argument > arena || active[id] { return -1 }
				mut target := 0
				mut rounded := 1
				for rounded < int(argument) { rounded *= 2; target++ }
				mut found_order := max_order + 1
				mut found_base := arena
				for order := target; order <= max_order; order++ {
					size := 1 << order
					for base := 0; base + size <= arena; base += size {
						if free_blocks[order][base] { found_order = order; found_base = base; break }
					}
					if found_order <= max_order { break }
				}
				if found_order > max_order {
					staged[staged_words], staged[staged_words + 1], staged[staged_words + 2] = 0, -1, 0
					staged_words += 3
					continue
				}
				free_blocks[found_order][found_base] = false
				for found_order > target {
					found_order--
					half := 1 << found_order
					free_blocks[found_order][found_base + half] = true
				}
				active[id] = true
				allocation_base[id], allocation_order[id] = found_base, target
				staged[staged_words], staged[staged_words + 1], staged[staged_words + 2] = 1, i64(found_base), i64(1 << target)
				staged_words += 3
			} else if opcode == 1 {
				if argument != 0 || !active[id] { return -1 }
				original_base := allocation_base[id]
				original_order := allocation_order[id]
				original_size := 1 << original_order
				active[id] = false
				mut base := original_base
				mut order := original_order
				for order < max_order {
					buddy := base ^ (1 << order)
					if !free_blocks[order][buddy] { break }
					free_blocks[order][buddy] = false
					if buddy < base { base = buddy }
					order++
				}
				free_blocks[order][base] = true
				staged[staged_words], staged[staged_words + 1], staged[staged_words + 2] = 1, i64(original_base), i64(original_size)
				staged_words += 3
			} else { return -1 }
		}
		count_index := staged_words
		staged[staged_words] = 0
		staged_words++
		for base in 0 .. arena {
			for order := max_order; order >= 0; order-- {
				if free_blocks[order][base] {
					staged[count_index]++
					staged[staged_words], staged[staged_words + 1] = i64(base), i64(1 << order)
					staged_words += 2
					break
				}
			}
		}
		required := staged_words * 8
		if output == nil || capacity < required { return -2 }
		for i in 0 .. staged_words {
			bits := u64(staged[i])
			for byte in 0 .. 8 { output[8 * i + byte] = u8(bits >> u64(8 * byte)) }
		}
		return i64(required)
	}
}
