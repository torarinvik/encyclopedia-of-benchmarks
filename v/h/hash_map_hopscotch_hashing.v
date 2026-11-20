const hs_slots = 16
const hs_h = 4
const hs_max_operations = 32
const hs_max_words = 1 + 3 * hs_max_operations

fn hs_distance(from int, to int) int {
	return (to - from + hs_slots) % hs_slots
}

fn hs_contains(keys []i16, hops []u8, key int, home int) bool {
	for offset in 0 .. hs_h {
		if (hops[home] & (u8(1) << offset)) != 0
			&& keys[(home + offset) % hs_slots] == i16(key) {
			return true
		}
	}
	return false
}

fn hs_insert(mut keys []i16, mut homes []u8, mut hops []u8, key int, home int) u8 {
	if hs_contains(keys, hops, key, home) {
		return 2
	}
	mut hole := -1
	for step in 0 .. hs_slots {
		slot := (home + step) % hs_slots
		if keys[slot] < 0 {
			hole = slot
			break
		}
	}
	if hole < 0 {
		return 0
	}
	mut reach := hs_distance(home, hole)
	for reach >= hs_h {
		mut shifted := false
		for back := hs_h - 1; back > 0 && !shifted; back-- {
			bucket := (hole - back + hs_slots) % hs_slots
			new_offset := hs_distance(bucket, hole)
			if hs_distance(home, bucket) >= reach {
				continue
			}
			for old_offset in 0 .. new_offset {
				if (hops[bucket] & (u8(1) << old_offset)) == 0 {
					continue
				}
				old_slot := (bucket + old_offset) % hs_slots
				if keys[old_slot] < 0 || int(homes[old_slot]) != bucket
					|| hs_distance(home, old_slot) >= reach {
					continue
				}
				keys[hole] = keys[old_slot]
				homes[hole] = homes[old_slot]
				keys[old_slot] = -1
				homes[old_slot] = 0
				hops[bucket] ^= u8(1) << old_offset
				hops[bucket] |= u8(1) << new_offset
				hole = old_slot
				reach = hs_distance(home, hole)
				shifted = true
				break
			}
		}
		if !shifted {
			return 0
		}
	}
	keys[hole] = i16(key)
	homes[hole] = u8(home)
	hops[home] |= u8(1) << reach
	return 1
}

@[export: 'hash_map_hopscotch_hashing']
pub fn hash_map_hopscotch_hashing(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > hs_max_words {
		return -1
	}
	count_value := unsafe { input[0] }
	if count_value < 0 || count_value > hs_max_operations {
		return -1
	}
	count := int(count_value)
	if length != usize(1 + 3 * count) {
		return -1
	}
	mut known_home := [64]i8{}
	for key in 0 .. 64 {
		known_home[key] = -1
	}
	for op in 0 .. count {
		opcode := unsafe { input[1 + 3 * op] }
		key := unsafe { input[2 + 3 * op] }
		home := unsafe { input[3 + 3 * op] }
		if (opcode != 1 && opcode != 2) || key < 0 || key >= 64 || home < 0 || home >= hs_slots {
			return -1
		}
		if known_home[int(key)] >= 0 && i64(known_home[int(key)]) != home {
			return -1
		}
		known_home[int(key)] = i8(home)
	}

	required := count + 2 * hs_slots
	if unsafe { output == nil } || capacity < usize(required) {
		return -2
	}
	mut keys := [16]i16{}
	mut homes := [16]u8{}
	mut hops := [16]u8{}
	mut statuses := [32]u8{}
	for slot in 0 .. hs_slots {
		keys[slot] = -1
	}
	for op in 0 .. count {
		opcode := unsafe { input[1 + 3 * op] }
		key := int(unsafe { input[2 + 3 * op] })
		home := int(unsafe { input[3 + 3 * op] })
		if opcode == 1 {
			statuses[op] = hs_insert(mut keys[..], mut homes[..], mut hops[..], key, home)
		} else {
			statuses[op] = u8(hs_contains(keys[..], hops[..], key, home))
		}
	}
	mut cursor := 0
	for op in 0 .. count {
		unsafe { output[cursor] = statuses[op] }
		cursor++
	}
	for key in keys {
		unsafe {
			output[cursor] = if key < 0 { 0 } else { u8(key + 1) }
		}
		cursor++
	}
	for mask in hops {
		unsafe { output[cursor] = mask }
		cursor++
	}
	return i64(required)
}
