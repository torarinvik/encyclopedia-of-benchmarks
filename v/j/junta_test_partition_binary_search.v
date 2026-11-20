fn truth_at(table &u64, point u32) i64 {
	unsafe {
		return i64((table[int(point / 64)] >> (point % 64)) & 1)
	}
}

fn store_i64_le(output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'junta_test_partition_binary_search']
pub fn junta_test_partition_binary_search(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if isnil(input) || length < 3 || length > 40 { return -1 }
		n64 := input[0]
		groups64 := input[1]
		words64 := input[2]
		if n64 < 1 || n64 > 8 || groups64 < 1 || groups64 > n64 { return -1 }
		n := int(n64)
		group_count := int(groups64)
		domain := 1 << n
		truth_words := (domain + 63) / 64
		if words64 != i64(truth_words) { return -1 }
		table_at := 3
		labels_at := table_at + truth_words
		tape_at := labels_at + n
		if length != usize(tape_at + 24) { return -1 }

		mut table := [4]u64{}
		for word in 0 .. truth_words { table[word] = u64(input[table_at + word]) }
		tail_bits := domain % 64
		if tail_bits != 0 && (table[truth_words - 1] >> tail_bits) != 0 { return -1 }

		mut group_masks := [8]u32{}
		mut groups_seen := u32(0)
		for coordinate in 0 .. n {
			group := input[labels_at + coordinate]
			if group < 0 || group >= groups64 { return -1 }
			group_masks[int(group)] |= u32(1) << coordinate
			groups_seen |= u32(1) << int(group)
		}
		if groups_seen != ((u32(1) << group_count) - 1) { return -1 }
		pair_limit := u64(1) << (2 * n)
		for round in 0 .. 24 {
			pair := input[tape_at + round]
			if pair < 0 || u64(pair) >= pair_limit { return -1 }
		}

		mut result := [7]i64{}
		mut event_rounds := [2]i64{}
		mut event_groups := [2]i64{}
		mut found := 0
		mut query_count := 0
		all_coordinates := (u32(1) << n) - 1
		mut active := all_coordinates
		for round in 0 .. 24 {
			packed := u64(input[tape_at + round])
			x := u32(packed & u64(all_coordinates))
			y := u32((packed >> n) & u64(all_coordinates))
			hybrid := (x & ~active) | (y & active)
			left_value := truth_at(&table[0], x)
			right_value := truth_at(&table[0], hybrid)
			query_count += 2
			if left_value != right_value {
				mut candidates := [8]u8{}
				mut candidate_count := 0
				for group in 0 .. group_count {
					if (group_masks[group] & active) != 0 {
						candidates[candidate_count] = u8(group)
						candidate_count++
					}
				}
				mut left_endpoint := x
				mut right_endpoint := hybrid
				for candidate_count > 1 {
					cut := candidate_count / 2
					mut low_mask := u32(0)
					for i in 0 .. cut { low_mask |= group_masks[int(candidates[i])] }
					probe := (left_endpoint & ~low_mask) | (right_endpoint & low_mask)
					probe_value := truth_at(&table[0], probe)
					query_count++
					if probe_value != left_value {
						right_endpoint = probe
						candidate_count = cut
					} else {
						left_endpoint = probe
						left_value = probe_value
						for i in cut .. candidate_count { candidates[i - cut] = candidates[i] }
						candidate_count -= cut
					}
				}
				selected := int(candidates[0])
				active &= ~group_masks[selected]
				event_rounds[found] = i64(round)
				event_groups[found] = i64(selected)
				found++
				if found > 1 { break }
			}
		}

		result[0] = 0
		if found > 1 { result[0] = 1 }
		result[1], result[2] = i64(found), i64(query_count)
		for i in 0 .. found {
			result[3 + 2 * i] = event_rounds[i]
			result[4 + 2 * i] = event_groups[i]
		}
		result_words := 3 + 2 * found
		result_bytes := result_words * 8
		if isnil(output) || capacity < usize(result_bytes) { return -2 }
		for i in 0 .. result_words { store_i64_le(output, i * 8, result[i]) }
		return i64(result_bytes)
	}
}
