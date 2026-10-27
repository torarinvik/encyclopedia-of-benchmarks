module point_pattern_translation_voting

const max_pattern = 6
const max_target = 8
const max_pairs = 48
const max_coord = 16

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'point_pattern_translation_voting']
pub fn point_pattern_translation_voting(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 31 { return -1 }
		pattern_raw := input[0]
		target_raw := input[1]
		if pattern_raw < 1 || pattern_raw > max_pattern || target_raw < 1 || target_raw > max_target { return -1 }
		pattern_count := int(pattern_raw)
		target_count := int(target_raw)
		if length != usize(2 + 2 * (pattern_count + target_count)) { return -1 }
		mut px := [max_pattern]i64{init: 0}
		mut py := [max_pattern]i64{init: 0}
		mut tx := [max_target]i64{init: 0}
		mut ty := [max_target]i64{init: 0}
		mut cursor := 2
		for i in 0 .. pattern_count {
			px[i] = input[cursor]
			py[i] = input[cursor + 1]
			cursor += 2
			if px[i] < -max_coord || px[i] > max_coord || py[i] < -max_coord || py[i] > max_coord { return -1 }
			for j in 0 .. i { if px[i] == px[j] && py[i] == py[j] { return -1 } }
		}
		for i in 0 .. target_count {
			tx[i] = input[cursor]
			ty[i] = input[cursor + 1]
			cursor += 2
			if tx[i] < -max_coord || tx[i] > max_coord || ty[i] < -max_coord || ty[i] > max_coord { return -1 }
			for j in 0 .. i { if tx[i] == tx[j] && ty[i] == ty[j] { return -1 } }
		}
		if output == nil { return -2 }
		mut dx := [max_pairs]i64{init: 0}
		mut dy := [max_pairs]i64{init: 0}
		mut pair_count := 0
		for p in 0 .. pattern_count {
			for t in 0 .. target_count {
				dx[pair_count] = tx[t] - px[p]
				dy[pair_count] = ty[t] - py[p]
				pair_count++
			}
		}
		for i in 1 .. pair_count {
			key_x := dx[i]
			key_y := dy[i]
			mut j := i
			for j > 0 && (dx[j - 1] > key_x || (dx[j - 1] == key_x && dy[j - 1] > key_y)) {
				dx[j] = dx[j - 1]
				dy[j] = dy[j - 1]
				j--
			}
			dx[j] = key_x
			dy[j] = key_y
		}
		mut best_count := 0
		mut best_x := dx[0]
		mut best_y := dy[0]
		mut i := 0
		for i < pair_count {
			mut ending := i + 1
			for ending < pair_count && dx[ending] == dx[i] && dy[ending] == dy[i] { ending++ }
			if ending - i > best_count {
				best_count = ending - i
				best_x = dx[i]
				best_y = dy[i]
			}
			i = ending
		}
		if capacity < 24 { return -2 }
		mut staged := [24]u8{init: 0}
		store_i64_le(mut staged[..], 0, i64(best_count))
		store_i64_le(mut staged[..], 8, best_x)
		store_i64_le(mut staged[..], 16, best_y)
		for byte in 0 .. 24 { output[byte] = staged[byte] }
		return 24
	}
}
