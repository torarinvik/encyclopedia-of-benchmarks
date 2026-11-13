package palindrome_pairs

import "core:c"

N :: 8
L :: 8
H :: 17

palindrome :: proc(words: [N][L]int, id, left, right: int) -> bool {
	lo, hi := left, right - 1
	for lo < hi {
		if words[id][lo] != words[id][hi] do return false
		lo += 1; hi -= 1
	}
	return true
}

encode :: proc(words: [N][L]int, id, left, right: int, reverse: bool) -> i64 {
	key: i64 = 1
	if reverse {
		i := right
		for i > left { i -= 1; key = key * 5 + i64(words[id][i] + 1) }
	} else {
		for i := left; i < right; i += 1 { key = key * 5 + i64(words[id][i] + 1) }
	}
	return key
}

slot_for :: proc(keys: [H]i64, key: i64) -> int {
	slot := int(key % H)
	for keys[slot] != 0 && keys[slot] != key { slot = (slot + 1) % H }
	return slot
}

mark :: proc(keys: [H]i64, heads: [H]int, next: [N]int, key: i64, fixed: int,
		fixed_right: bool, found: ^[N][N]bool) {
	slot := slot_for(keys, key)
	if keys[slot] != key do return
	id := heads[slot]
	for id >= 0 {
		if id != fixed {
			if fixed_right { found[id][fixed] = true } else { found[fixed][id] = true }
		}
		id = next[id]
	}
}

@(export)
palindrome_pairs :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 74 || input[0] < 0 || input[0] > N do return -1
	count := int(input[0]); words: [N][L]int = {}; sizes: [N]int = {}; cursor := 1
	for id := 0; id < count; id += 1 {
		if cursor >= int(length) || input[cursor] < 0 || input[cursor] > L do return -1
		size := int(input[cursor]); cursor += 1
		if cursor + size > int(length) do return -1
		sizes[id] = size
		for k := 0; k < size; k += 1 {
			if input[cursor] < 0 || input[cursor] >= 4 do return -1
			words[id][k] = int(input[cursor]); cursor += 1
		}
	}
	if cursor != int(length) do return -1
	keys: [H]i64 = {}; heads: [H]int = {}; next: [N]int = {}
	for i := 0; i < H; i += 1 { heads[i] = -1 }
	for i := 0; i < N; i += 1 { next[i] = -1 }
	for id := 0; id < count; id += 1 {
		key := encode(words, id, 0, sizes[id], false); slot := slot_for(keys, key)
		if keys[slot] == 0 { keys[slot] = key; heads[slot] = id }
		else { next[id] = heads[slot]; heads[slot] = id }
	}
	found: [N][N]bool = {}
	for id := 0; id < count; id += 1 {
		for split := 0; split <= sizes[id]; split += 1 {
			if palindrome(words, id, 0, split) { mark(keys, heads, next, encode(words, id, split, sizes[id], true), id, true, &found) }
			if palindrome(words, id, split, sizes[id]) { mark(keys, heads, next, encode(words, id, 0, split, true), id, false, &found) }
		}
	}
	staged: [N*(N-1)]u8 = {}; bytes := 0
	for left := 0; left < count; left += 1 {
		for right := 0; right < count; right += 1 {
			if left != right && found[left][right] { staged[bytes] = u8(left*N+right); bytes += 1 }
		}
	}
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i := 0; i < bytes; i += 1 { output[i] = staged[i] }
	return i64(bytes)
}
