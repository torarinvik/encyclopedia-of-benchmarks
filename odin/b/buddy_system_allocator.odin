package buddy_system_allocator

import "core:c"

ARENA :: 256
MAX_ORDER :: 8
MAX_OPS :: 64
MAX_IDS :: 32
MAX_INPUT_WORDS :: 194
MAX_OUTPUT_WORDS :: 3 * MAX_OPS + 1 + 2 * ARENA

@(export)
buddy_system_allocator :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_INPUT_WORDS do return -1
	raw_count := values[0]
	if raw_count < 0 || raw_count > MAX_OPS || length != c.size_t(1 + 3 * raw_count) do return -1
	count := int(raw_count)

	free_blocks: [MAX_ORDER + 1][ARENA]bool
	active: [MAX_IDS]bool
	allocation_base: [MAX_IDS]int
	allocation_order: [MAX_IDS]int
	staged: [MAX_OUTPUT_WORDS]i64
	for order := 0; order <= MAX_ORDER; order += 1 {
		for base := 0; base < ARENA; base += 1 { free_blocks[order][base] = false }
	}
	for id := 0; id < MAX_IDS; id += 1 { active[id] = false }
	free_blocks[MAX_ORDER][0] = true
	staged_words := 0

	for i := 0; i < count; i += 1 {
		opcode := values[1 + 3 * i]
		raw_id := values[2 + 3 * i]
		argument := values[3 + 3 * i]
		if raw_id < 0 || raw_id >= MAX_IDS do return -1
		id := int(raw_id)
		if opcode == 0 {
			if argument < 1 || argument > ARENA || active[id] do return -1
			target, rounded := 0, 1
			for rounded < int(argument) { rounded *= 2; target += 1 }
			found_order, found_base := MAX_ORDER + 1, ARENA
			for order := target; order <= MAX_ORDER; order += 1 {
				size := 1 << order
				for base := 0; base + size <= ARENA; base += size {
					if free_blocks[order][base] { found_order, found_base = order, base; break }
				}
				if found_order <= MAX_ORDER do break
			}
			if found_order > MAX_ORDER {
				staged[staged_words], staged[staged_words + 1], staged[staged_words + 2] = 0, -1, 0
				staged_words += 3
				continue
			}
			free_blocks[found_order][found_base] = false
			for found_order > target {
				found_order -= 1
				half := 1 << found_order
				free_blocks[found_order][found_base + half] = true
			}
			active[id] = true
			allocation_base[id], allocation_order[id] = found_base, target
			staged[staged_words], staged[staged_words + 1], staged[staged_words + 2] = 1, i64(found_base), i64(1 << target)
			staged_words += 3
		} else if opcode == 1 {
			if argument != 0 || !active[id] do return -1
			original_base, original_order := allocation_base[id], allocation_order[id]
			original_size := 1 << original_order
			active[id] = false
			base, order := original_base, original_order
			for order < MAX_ORDER {
				buddy := base ^ (1 << order)
				if !free_blocks[order][buddy] do break
				free_blocks[order][buddy] = false
				if buddy < base do base = buddy
				order += 1
			}
			free_blocks[order][base] = true
			staged[staged_words], staged[staged_words + 1], staged[staged_words + 2] = 1, i64(original_base), i64(original_size)
			staged_words += 3
		} else do return -1
	}

	count_index := staged_words
	staged[staged_words] = 0
	staged_words += 1
	for base := 0; base < ARENA; base += 1 {
		for order := MAX_ORDER; order >= 0; order -= 1 {
			if free_blocks[order][base] {
				staged[count_index] += 1
				staged[staged_words], staged[staged_words + 1] = i64(base), i64(1 << order)
				staged_words += 2
				break
			}
		}
	}
	required := c.size_t(staged_words * 8)
	if output == nil || capacity < required do return -2
	for i := 0; i < staged_words; i += 1 {
		bits := u64(staged[i])
		for byte := 0; byte < 8; byte += 1 { output[8 * i + byte] = u8(bits >> u64(8 * byte)) }
	}
	return i64(required)
}
