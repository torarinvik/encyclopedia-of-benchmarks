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

module ptrdist_anagram

const max_phrase = 16
const max_words = 12
const max_word_length = 16
const alphabet = 26

struct Candidate {
	mask u64
	length int
}

struct Search {
mut:
	candidates [max_words]Candidate
	candidate_count int
	order [alphabet]int
	letter_mask [alphabet]u64
	sign_mask u64
}

fn letter_index(value i64) int {
	if value >= 97 && value <= 122 { return int(value - 97) }
	if value >= 65 && value <= 90 { return int(value - 65) }
	return -1
}

fn find_anagrams(mut search Search, remaining_mask u64, remaining_length int, start_value int, first_letter int) i64 {
	if remaining_length == 0 { return 1 }
	mut pivot_position := first_letter
	for pivot_position < alphabet {
		letter := search.order[pivot_position]
		if (remaining_mask & search.letter_mask[letter]) != 0 { break }
		pivot_position++
	}
	if pivot_position == alphabet { return 0 }
	pivot := search.order[pivot_position]
	mut start := start_value
	mut ending := search.candidate_count
	mut solutions := i64(0)
	for start < ending {
		candidate := search.candidates[start]
		after := remaining_mask - candidate.mask
		if (after & search.sign_mask) != 0 { start++; continue }
		if (candidate.mask & search.letter_mask[pivot]) == 0 {
			search.candidates[start] = search.candidates[ending - 1]
			search.candidates[ending - 1] = candidate
			ending--
			continue
		}
		next_length := remaining_length - candidate.length
		if next_length == 0 { solutions++ }
		else { solutions += find_anagrams(mut search, after, next_length, start, pivot_position) }
		start++
	}
	return solutions
}

@[export: 'ptrdist_anagram']
pub fn ptrdist_anagram(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 222 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > i64(max_phrase) { return -1 }
		phrase_length := int(input[0])
		count_offset := phrase_length + 1
		if usize(count_offset) >= length || input[count_offset] < 0 || input[count_offset] > i64(max_words) { return -1 }
		mut phrase_counts := [alphabet]u8{}
		for i in 0 .. phrase_length {
			letter := letter_index(input[i + 1])
			if letter < 0 { return -1 }
			phrase_counts[letter]++
		}

		word_count := int(input[count_offset])
		mut offset := count_offset + 1
		mut phrase_mask := u64(0)
		mut sign_mask := u64(0)
		mut letter_mask := [alphabet]u64{}
		mut letter_shift := [alphabet]u32{}
		mut global_frequency := [alphabet]u32{}
		mut shift := u32(0)
		for letter in 0 .. alphabet {
			frequency := u32(phrase_counts[letter])
			if frequency == 0 { continue }
			mut count_bits := u32(1)
			for (u32(1) << count_bits) <= frequency { count_bits++ }
			if shift + count_bits + 1 > 64 { return -1 }
			letter_mask[letter] = ((u64(1) << count_bits) - 1) << shift
			phrase_mask |= u64(frequency) << shift
			sign_mask |= u64(1) << (shift + count_bits)
			letter_shift[letter] = shift
			shift += count_bits + 1
		}

		mut search := Search{sign_mask: sign_mask, letter_mask: letter_mask}
		for _ in 0 .. word_count {
			if offset >= int(length) || input[offset] < 1 || input[offset] > i64(max_word_length) { return -1 }
			word_length := int(input[offset]); offset++
			if word_length > int(length) - offset { return -1 }
			mut counts := [alphabet]u8{}
			for i in 0 .. word_length {
				letter := letter_index(input[offset + i])
				if letter < 0 { return -1 }
				counts[letter]++
			}
			mut fits := true
			for letter in 0 .. alphabet { if counts[letter] > phrase_counts[letter] { fits = false } }
			if fits && ((word_length >= 2 && word_length + 2 <= phrase_length) || word_length == phrase_length) {
				mut mask := u64(0)
				for letter in 0 .. alphabet {
					mask |= u64(counts[letter]) << letter_shift[letter]
					global_frequency[letter] += u32(counts[letter])
				}
				search.candidates[search.candidate_count] = Candidate{mask, word_length}
				search.candidate_count++
			}
			offset += word_length
		}
		if offset != int(length) { return -1 }

		for letter in 0 .. alphabet { search.order[letter] = letter }
		for i in 1 .. alphabet {
			key := search.order[i]
			mut j := i
			for j > 0 {
				previous := search.order[j - 1]
				mut previous_frequency := global_frequency[previous]
				mut key_frequency := global_frequency[key]
				if previous_frequency == 0 { previous_frequency = 0xffffffff }
				if key_frequency == 0 { key_frequency = 0xffffffff }
				if previous_frequency < key_frequency || (previous_frequency == key_frequency && previous < key) { break }
				search.order[j] = search.order[j - 1]
				j--
			}
			search.order[j] = key
		}
		return find_anagrams(mut search, phrase_mask, phrase_length, 0, 0)
	}
}
