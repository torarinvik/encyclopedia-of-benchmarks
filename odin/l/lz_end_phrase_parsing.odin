package lz_end_phrase_parsing

import "core:c"

MAX_TEXT :: 64
MAX_INPUT :: 66
PHRASE_MULTIPLIER :: i64(133121)

@(export)
lz_end_phrase_parsing :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT do return -1
	n64 := input[0]
	if n64 < 0 || n64 > MAX_TEXT || length != c.size_t(n64 + 1) do return -1
	n := int(n64)
	for i := 0; i < n; i += 1 { if input[i+1] < 0 || input[i+1] > 255 do return -1 }
	var boundaries: [MAX_TEXT]int
	var phrase_lengths: [MAX_TEXT]int
	phrases, position := 0, 0
	for position < n {
		best_copy := 0
		for copy_length := n-position-1; copy_length > 0 && best_copy == 0; copy_length -= 1 {
			for prior := phrases-1; prior >= 0 && best_copy == 0; prior -= 1 {
				boundary := boundaries[prior]
				if boundary < copy_length do continue
				matches := true
				for offset := 0; offset < copy_length; offset += 1 {
					if input[1+position+offset] != input[1+boundary-copy_length+offset] { matches = false; break }
				}
				if matches { best_copy = copy_length }
			}
		}
		phrase_lengths[phrases] = best_copy + 1
		position += phrase_lengths[phrases]
		boundaries[phrases] = position
		phrases += 1
	}
	checksum: i64 = 0
	for i := 0; i < phrases; i += 1 { checksum += i64(i+1) * i64(phrase_lengths[i]) }
	return PHRASE_MULTIPLIER * i64(phrases) + checksum
}
