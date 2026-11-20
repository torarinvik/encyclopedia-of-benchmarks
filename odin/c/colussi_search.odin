package colussi_search

import "core:c"

MAX_TEXT_LENGTH :: 4096
MAX_PATTERN_LENGTH :: 128
MAX_INPUT_LENGTH :: 4227

preprocess :: proc "contextless" (pattern: [^]u8, pattern_length: int,
	h, next_table, shift: [^]int) -> int {
	var hmax: [MAX_PATTERN_LENGTH+2]int
	var kmin, rmin, nhd0: [MAX_PATTERN_LENGTH+1]int
	i, k := 1, 1
	for {
		for pattern[i] == pattern[i-k] { i += 1 }
		hmax[k] = i
		q := k + 1
		for hmax[q-k]+k < i {
			hmax[q] = hmax[q-k] + k
			q += 1
		}
		k = q
		if k == i+1 do i = k
		if k > pattern_length do break
	}
	for i = pattern_length; i >= 1; i -= 1 {
		if hmax[i] < pattern_length do kmin[hmax[i]] = i
	}
	r := pattern_length
	for i = pattern_length-1; i >= 0; i -= 1 {
		if hmax[i+1] == pattern_length do r = i+1
		if kmin[i] == 0 { rmin[i] = r } else { rmin[i] = 0 }
	}
	nohole_last, hole_at := -1, pattern_length
	for position := 0; position < pattern_length; position += 1 {
		if kmin[position] == 0 {
			hole_at -= 1
			h[hole_at] = position
		} else {
			nohole_last += 1
			h[nohole_last] = position
		}
	}
	nd := nohole_last
	for position := 0; position <= nd; position += 1 do shift[position] = kmin[h[position]]
	for position := nd+1; position < pattern_length; position += 1 do shift[position] = rmin[h[position]]
	shift[pattern_length] = rmin[0]
	nohole_count := 0
	for position := 0; position < pattern_length; position += 1 {
		 nhd0[position] = nohole_count
		if kmin[position] > 0 do nohole_count += 1
	}
	for position := 0; position <= nd; position += 1 do next_table[position] = nhd0[h[position]-kmin[h[position]]]
	for position := nd+1; position < pattern_length; position += 1 do next_table[position] = nhd0[pattern_length-rmin[h[position]]]
	next_table[pattern_length] = nhd0[pattern_length-rmin[h[pattern_length-1]]]
	return nd
}

@(export)
colussi_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	text_length64, pattern_length64 := input[0], input[1]
	if text_length64 < 0 || text_length64 > MAX_TEXT_LENGTH || pattern_length64 < 1 || pattern_length64 > MAX_PATTERN_LENGTH do return -1
	text_length, pattern_length := int(text_length64), int(pattern_length64)
	if length != c.size_t(2+text_length+pattern_length) do return -1
	var text: [MAX_TEXT_LENGTH]u8
	var pattern: [MAX_PATTERN_LENGTH+1]u8
	for i := 0; i < text_length; i += 1 {
		symbol := input[2+i]
		if symbol < 0 || symbol > 3 do return -1
		text[i] = u8(symbol)
	}
	pattern_offset := 2+text_length
	for i := 0; i < pattern_length; i += 1 {
		symbol := input[pattern_offset+i]
		if symbol < 0 || symbol > 3 do return -1
		pattern[i] = u8(symbol)
	}
	pattern[pattern_length] = 4
	if text_length < pattern_length do return 0
	var h, next_table, shift: [MAX_PATTERN_LENGTH+1]int
	nd := preprocess(&pattern[0], pattern_length, &h[0], &next_table[0], &shift[0])
	i, j, last := 0, 0, -1
	var match_count, offset_sum, offset_xor: i64
	for j <= text_length-pattern_length {
		for i < pattern_length && last < j+h[i] && pattern[h[i]] == text[j+h[i]] { i += 1 }
		if i >= pattern_length || last >= j+h[i] {
			match_count += 1
			offset_sum += i64(j)
			offset_xor = offset_xor ~ i64(j)
			i = pattern_length
		}
		if i > nd do last = j+pattern_length-1
		j += shift[i]
		i = next_table[i]
	}
	return (match_count << 36) | (offset_sum << 12) | offset_xor
}
