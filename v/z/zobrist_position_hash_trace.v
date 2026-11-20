module zobrist_position_hash_trace

const slots = 16
const features = 3
const max_operations = 64
const base_words = 1 + slots * features + slots
const max_valid_words = base_words + 2 * max_operations

fn store_hash(mut output &u8, offset usize, value u64) {
	for byte in 0 .. 8 {
		unsafe { output[offset + usize(byte)] = u8((value >> u32(byte * 8)) & 255) }
	}
}

@[export: 'zobrist_position_hash_trace']
pub fn zobrist_position_hash_trace(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < base_words || length > max_valid_words + 1 { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 0 || count_value > max_operations { return -1 }
	count := int(count_value)
	if length != base_words + 2 * usize(count) { return -1 }

	for index in 0 .. slots * features {
		if unsafe { input[1 + index] } < 0 { return -1 }
	}
	state_start := 1 + slots * features
	for slot in 0 .. slots {
		feature := unsafe { input[state_start + slot] }
		if feature < 0 || feature > features { return -1 }
	}
	edits_start := state_start + slots
	for edit in 0 .. count {
		slot := unsafe { input[edits_start + 2 * edit] }
		feature := unsafe { input[edits_start + 2 * edit + 1] }
		if slot < 0 || slot >= slots || feature < 0 || feature > features { return -1 }
	}

	required := 8 * (count + 1)
	if unsafe { output == nil } || capacity < usize(required) { return -2 }

	mut board := [slots]u8{}
	mut hash := u64(0)
	for slot in 0 .. slots {
		feature := u8(unsafe { input[state_start + slot] })
		board[slot] = feature
		if feature != 0 {
			hash ^= u64(unsafe { input[1 + slot * features + int(feature) - 1] })
		}
	}
	store_hash(mut output, 0, hash)
	for edit in 0 .. count {
		slot := int(unsafe { input[edits_start + 2 * edit] })
		next := u8(unsafe { input[edits_start + 2 * edit + 1] })
		previous := board[slot]
		if previous != 0 {
			hash ^= u64(unsafe { input[1 + slot * features + int(previous) - 1] })
		}
		if next != 0 {
			hash ^= u64(unsafe { input[1 + slot * features + int(next) - 1] })
		}
		board[slot] = next
		store_hash(mut output, 8 * (edit + 1), hash)
	}
	return i64(required)
}
