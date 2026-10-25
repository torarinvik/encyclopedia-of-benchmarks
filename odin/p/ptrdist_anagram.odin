/*
 * Anagram program by Raymond Chen,
 * inspired by a similar program by Brian Scearce
 *
 * This program is Copyright 1991 by Raymond Chen.
 *             (rjc@math.princeton.edu)
 *
 * This program may be freely distributed provided all alterations
 * to the original are clearly indicated as such.
 * Alterations: bounded packed-array input, portable 64-bit packed counts,
 * and a scalar decomposition count instead of periodic printing.
 */

package ptrdist_anagram

import "core:c"

MAX_PHRASE :: 16
MAX_WORDS :: 12
MAX_WORD_LENGTH :: 16
ALPHABET :: 26

Candidate :: struct { mask: u64, length: i32 }
Search :: struct {
	candidates: [MAX_WORDS]Candidate,
	candidate_count: int,
	order: [ALPHABET]int,
	letter_mask: [ALPHABET]u64,
	sign_mask: u64,
}

letter_index :: proc "contextless" (value: i64) -> int {
	if value >= 97 && value <= 122 do return int(value - 97)
	if value >= 65 && value <= 90 do return int(value - 65)
	return -1
}

find_anagrams :: proc "contextless" (search: ^Search, remaining_mask: u64, remaining_length: int, start: int, first_letter: int) -> i64 {
	if remaining_length == 0 do return 1
	pivot_position := first_letter
	for pivot_position < ALPHABET {
		letter := search.order[pivot_position]
		if (remaining_mask & search.letter_mask[letter]) != 0 do break
		pivot_position += 1
	}
	if pivot_position == ALPHABET do return 0
	pivot := search.order[pivot_position]
	ending := search.candidate_count
	total := i64(0)
	for start < ending {
		candidate := search.candidates[start]
		after := remaining_mask - candidate.mask
		if (after & search.sign_mask) != 0 { start += 1; continue }
		if (candidate.mask & search.letter_mask[pivot]) == 0 {
			search.candidates[start] = search.candidates[ending-1]
			search.candidates[ending-1] = candidate
			ending -= 1
			continue
		}
		next_length := remaining_length - int(candidate.length)
		if next_length == 0 { total += 1 } else { total += find_anagrams(search, after, next_length, start, pivot_position) }
		start += 1
	}
	return total
}

@(export)
ptrdist_anagram :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 222 || input[0] < 1 || input[0] > MAX_PHRASE do return -1
	phrase_length := int(input[0])
	count_offset := phrase_length + 1
	if c.size_t(count_offset) >= length || input[count_offset] < 0 || input[count_offset] > MAX_WORDS do return -1
	phrase_counts: [ALPHABET]u8
	for i := 0; i < phrase_length; i += 1 {
		letter := letter_index(input[i+1])
		if letter < 0 do return -1
		phrase_counts[letter] += 1
	}

	word_count := int(input[count_offset])
	offset := count_offset + 1
	phrase_mask := u64(0)
	sign_mask := u64(0)
	letter_mask: [ALPHABET]u64
	letter_shift: [ALPHABET]u32
	global_frequency: [ALPHABET]u32
	shift := u32(0)
	for letter := 0; letter < ALPHABET; letter += 1 {
		frequency := u32(phrase_counts[letter])
		if frequency == 0 do continue
		count_bits := u32(1)
		for (u32(1) << count_bits) <= frequency { count_bits += 1 }
		if shift + count_bits + 1 > 64 do return -1
		letter_mask[letter] = ((u64(1) << count_bits) - 1) << shift
		phrase_mask |= u64(frequency) << shift
		sign_mask |= u64(1) << (shift + count_bits)
		letter_shift[letter] = shift
		shift += count_bits + 1
	}

	search := Search{sign_mask = sign_mask, letter_mask = letter_mask}
	for word_index := 0; word_index < word_count; word_index += 1 {
		if c.size_t(offset) >= length || input[offset] < 1 || input[offset] > MAX_WORD_LENGTH do return -1
		word_length := int(input[offset]); offset += 1
		if c.size_t(word_length) > length - c.size_t(offset) do return -1
		counts: [ALPHABET]u8
		for i := 0; i < word_length; i += 1 {
			letter := letter_index(input[offset+i])
			if letter < 0 do return -1
			counts[letter] += 1
		}
		fits := true
		for letter := 0; letter < ALPHABET; letter += 1 { if counts[letter] > phrase_counts[letter] do fits = false }
		if fits && ((word_length >= 2 && word_length + 2 <= phrase_length) || word_length == phrase_length) {
			mask := u64(0)
			for letter := 0; letter < ALPHABET; letter += 1 {
				mask |= u64(counts[letter]) << letter_shift[letter]
				global_frequency[letter] += u32(counts[letter])
			}
			search.candidates[search.candidate_count] = Candidate{mask, i32(word_length)}
			search.candidate_count += 1
		}
		offset += word_length
	}
	if c.size_t(offset) != length do return -1

	for letter := 0; letter < ALPHABET; letter += 1 { search.order[letter] = letter }
	for i := 1; i < ALPHABET; i += 1 {
		key := search.order[i]; j := i
		for j > 0 {
			previous := search.order[j-1]
			previous_frequency := global_frequency[previous]
			key_frequency := global_frequency[key]
			if previous_frequency == 0 do previous_frequency = 0xffffffff
			if key_frequency == 0 do key_frequency = 0xffffffff
			if previous_frequency < key_frequency || (previous_frequency == key_frequency && previous < key) do break
			search.order[j] = previous; j -= 1
		}
		search.order[j] = key
	}
	return find_anagrams(&search, phrase_mask, phrase_length, 0, 0)
}
