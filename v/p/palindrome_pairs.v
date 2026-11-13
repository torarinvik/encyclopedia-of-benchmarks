module palindrome_pairs

const word_count_max = 8
const word_length_max = 8
const hash_capacity = 17

fn pp_palindrome(words [64]int, id int, left int, right int) bool {
	mut lo := left
	mut hi := right - 1
	for lo < hi {
		if words[id * 8 + lo] != words[id * 8 + hi] { return false }
		lo++
		hi--
	}
	return true
}

fn pp_encode(words [64]int, id int, left int, right int, reverse bool) i64 {
	mut key := i64(1)
	if reverse {
		mut i := right
		for i > left { i--; key = key * 5 + i64(words[id * 8 + i] + 1) }
	} else {
		for i in left .. right { key = key * 5 + i64(words[id * 8 + i] + 1) }
	}
	return key
}

fn pp_slot(keys [17]i64, key i64) int {
	mut slot := int(key % hash_capacity)
	for keys[slot] != 0 && keys[slot] != key { slot = (slot + 1) % hash_capacity }
	return slot
}

fn pp_mark(keys [17]i64, heads [17]int, next [8]int, key i64, fixed int, fixed_right bool, mut found [64]bool) {
	slot := pp_slot(keys, key)
	if keys[slot] != key { return }
	mut id := heads[slot]
	for id >= 0 {
		if id != fixed {
			if fixed_right { found[id * 8 + fixed] = true }
			else { found[fixed * 8 + id] = true }
		}
		id = next[id]
	}
}

@[export: 'palindrome_pairs']
pub fn palindrome_pairs(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 74 || input[0] < 0 || input[0] > word_count_max { return -1 }
		count := int(input[0])
		mut words := [64]int{}
		mut sizes := [8]int{}
		mut cursor := 1
		for id in 0 .. count {
			if cursor >= int(length) || input[cursor] < 0 || input[cursor] > word_length_max { return -1 }
			size := int(input[cursor]); cursor++
			if cursor + size > int(length) { return -1 }
			sizes[id] = size
			for k in 0 .. size {
				if input[cursor] < 0 || input[cursor] >= 4 { return -1 }
				words[id * 8 + k] = int(input[cursor]); cursor++
			}
		}
		if cursor != int(length) { return -1 }
		mut keys := [17]i64{}
		mut heads := [17]int{}
		mut next := [8]int{}
		for i in 0 .. hash_capacity { heads[i] = -1 }
		for i in 0 .. word_count_max { next[i] = -1 }
		for id in 0 .. count {
			key := pp_encode(words, id, 0, sizes[id], false)
			slot := pp_slot(keys, key)
			if keys[slot] == 0 { keys[slot] = key; heads[slot] = id }
			else { next[id] = heads[slot]; heads[slot] = id }
		}
		mut found := [64]bool{}
		for id in 0 .. count {
			for split in 0 .. sizes[id] + 1 {
				if pp_palindrome(words, id, 0, split) { pp_mark(keys, heads, next, pp_encode(words, id, split, sizes[id], true), id, true, mut found) }
				if pp_palindrome(words, id, split, sizes[id]) { pp_mark(keys, heads, next, pp_encode(words, id, 0, split, true), id, false, mut found) }
			}
		}
		mut staged := [56]u8{}
		mut bytes := 0
		for left in 0 .. count {
			for right in 0 .. count {
				if left != right && found[left * 8 + right] { staged[bytes] = u8(left * 8 + right); bytes++ }
			}
		}
		if output == nil || capacity < bytes { return -2 }
		for i in 0 .. bytes { output[i] = staged[i] }
		return i64(bytes)
	}
}
