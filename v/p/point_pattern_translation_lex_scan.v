module point_pattern_translation_lex_scan

const max_pattern = 6
const max_target = 8
const max_coord = 16

fn point_less(ax i64, ay i64, bx i64, by i64) bool {
	return ax < bx || (ax == bx && ay < by)
}

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'point_pattern_translation_lex_scan']
pub fn point_pattern_translation_lex_scan(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 31 { return -1 }
		pattern_raw := input[0]
		target_raw := input[1]
		if pattern_raw < 1 || pattern_raw > max_pattern || target_raw < 1 || target_raw > max_target || pattern_raw > target_raw { return -1 }
		pattern_count := int(pattern_raw)
		target_count := int(target_raw)
		if length != usize(2 + 2 * (pattern_count + target_count)) { return -1 }
		mut px := [max_pattern]i64{init: 0}
		mut py := [max_pattern]i64{init: 0}
		mut tx := [max_target]i64{init: 0}
		mut ty := [max_target]i64{init: 0}
		mut cursor := 2
		for i in 0 .. pattern_count {
			px[i] = input[cursor]; py[i] = input[cursor + 1]; cursor += 2
			if px[i] < -max_coord || px[i] > max_coord || py[i] < -max_coord || py[i] > max_coord { return -1 }
			if i > 0 && !point_less(px[i - 1], py[i - 1], px[i], py[i]) { return -1 }
		}
		for i in 0 .. target_count {
			tx[i] = input[cursor]; ty[i] = input[cursor + 1]; cursor += 2
			if tx[i] < -max_coord || tx[i] > max_coord || ty[i] < -max_coord || ty[i] > max_coord { return -1 }
			if i > 0 && !point_less(tx[i - 1], ty[i - 1], tx[i], ty[i]) { return -1 }
		}
		if output == nil || capacity < 24 { return -2 }

		mut found := i64(0)
		mut best_x := i64(0)
		mut best_y := i64(0)
		for anchor in 0 .. target_count {
			dx := tx[anchor] - px[0]
			dy := ty[anchor] - py[0]
			mut target_index := anchor + 1
			mut matches := true
			for pattern_index in 1 .. pattern_count {
				wanted_x := px[pattern_index] + dx
				wanted_y := py[pattern_index] + dy
				for target_index < target_count && point_less(tx[target_index], ty[target_index], wanted_x, wanted_y) { target_index++ }
				if target_index >= target_count || tx[target_index] != wanted_x || ty[target_index] != wanted_y { matches = false; break }
				target_index++
			}
			if matches { found = 1; best_x = dx; best_y = dy; break }
		}
		mut staged := [24]u8{}
		store_i64_le(mut staged[..], 0, found)
		store_i64_le(mut staged[..], 8, best_x)
		store_i64_le(mut staged[..], 16, best_y)
		for byte in 0 .. 24 { output[byte] = staged[byte] }
		return 24
	}
}
