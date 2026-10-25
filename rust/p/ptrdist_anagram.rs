/*
 * Anagram program by Raymond Chen,
 * inspired by a similar program by Brian Scearce
 *
 * This program is Copyright 1991 by Raymond Chen.
 *             (rjc@math.princeton.edu)
 *
 * This program may be freely distributed provided all alterations
 * to the original are clearly indicated as such.
 *
 * Alterations for this benchmark port: replace the command-line, dictionary
 * file, and interactive stream interface with a bounded packed-array input;
 * use a portable 64-bit packed frequency word; and return the number of
 * decompositions instead of periodically printing them.
 */

const MAX_PHRASE: usize = 16;
const MAX_WORDS: usize = 12;
const MAX_WORD_LENGTH: usize = 16;
const ALPHABET: usize = 26;

#[derive(Clone, Copy, Default)]
struct Candidate { mask: u64, length: i32 }

struct Search {
    candidates: [Candidate; MAX_WORDS],
    candidate_count: usize,
    order: [usize; ALPHABET],
    letter_mask: [u64; ALPHABET],
    sign_mask: u64,
}

fn letter_index(value: i64) -> Option<usize> {
    match value {
        97..=122 => Some((value - 97) as usize),
        65..=90 => Some((value - 65) as usize),
        _ => None,
    }
}

fn find_anagrams(search: &mut Search, remaining_mask: u64, remaining_length: i32,
                 mut start: usize, first_letter: usize) -> i64 {
    if remaining_length == 0 { return 1; }
    let mut pivot_position = first_letter;
    while pivot_position < ALPHABET {
        let letter = search.order[pivot_position];
        if remaining_mask & search.letter_mask[letter] != 0 { break; }
        pivot_position += 1;
    }
    if pivot_position == ALPHABET { return 0; }
    let pivot = search.order[pivot_position];
    let mut end = search.candidate_count;
    let mut solutions = 0i64;
    while start < end {
        let candidate = search.candidates[start];
        let after = remaining_mask.wrapping_sub(candidate.mask);
        if after & search.sign_mask != 0 { start += 1; continue; }
        if candidate.mask & search.letter_mask[pivot] == 0 {
            search.candidates[start] = search.candidates[end - 1];
            search.candidates[end - 1] = candidate;
            end -= 1;
            continue;
        }
        let next_length = remaining_length - candidate.length;
        solutions += if next_length == 0 { 1 } else {
            find_anagrams(search, after, next_length, start, pivot_position)
        };
        start += 1;
    }
    solutions
}

#[no_mangle]
pub unsafe extern "C" fn ptrdist_anagram(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > 222 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_PHRASE as i64).contains(&values[0]) { return -1; }
    let phrase_length = values[0] as usize;
    let count_offset = phrase_length + 1;
    if count_offset >= length || values[count_offset] < 0 || values[count_offset] > MAX_WORDS as i64 { return -1; }
    let mut phrase_counts = [0u8; ALPHABET];
    for i in 0..phrase_length {
        let Some(letter) = letter_index(values[i + 1]) else { return -1; };
        phrase_counts[letter] += 1;
    }

    let word_count = values[count_offset] as usize;
    let mut offset = count_offset + 1;
    let mut phrase_mask = 0u64;
    let mut sign_mask = 0u64;
    let mut letter_mask = [0u64; ALPHABET];
    let mut letter_shift = [0u32; ALPHABET];
    let mut global_frequency = [0u32; ALPHABET];
    let mut shift = 0u32;
    for letter in 0..ALPHABET {
        let frequency = phrase_counts[letter] as u32;
        if frequency == 0 { continue; }
        let mut count_bits = 1u32;
        while (1u32 << count_bits) <= frequency { count_bits += 1; }
        if shift + count_bits + 1 > 64 { return -1; }
        letter_mask[letter] = ((1u64 << count_bits) - 1) << shift;
        phrase_mask |= (frequency as u64) << shift;
        sign_mask |= 1u64 << (shift + count_bits);
        letter_shift[letter] = shift;
        shift += count_bits + 1;
    }

    let mut search = Search {
        candidates: [Candidate::default(); MAX_WORDS], candidate_count: 0,
        order: [0; ALPHABET], letter_mask, sign_mask,
    };
    for word_index in 0..word_count {
        if offset >= length || values[offset] < 1 || values[offset] > MAX_WORD_LENGTH as i64 { return -1; }
        let word_length = values[offset] as usize;
        offset += 1;
        if word_length > length - offset { return -1; }
        let mut counts = [0u8; ALPHABET];
        for i in 0..word_length {
            let Some(letter) = letter_index(values[offset + i]) else { return -1; };
            counts[letter] += 1;
        }
        let mut fits = true;
        for letter in 0..ALPHABET {
            if counts[letter] > phrase_counts[letter] { fits = false; }
        }
        if fits && ((word_length >= 2 && word_length + 2 <= phrase_length) || word_length == phrase_length) {
            let mut mask = 0u64;
            for letter in 0..ALPHABET {
                mask |= (counts[letter] as u64) << letter_shift[letter];
                global_frequency[letter] += counts[letter] as u32;
            }
            search.candidates[search.candidate_count] = Candidate { mask, length: word_length as i32 };
            search.candidate_count += 1;
        }
        offset += word_length;
        let _ = word_index;
    }
    if offset != length { return -1; }

    for letter in 0..ALPHABET { search.order[letter] = letter; }
    for i in 1..ALPHABET {
        let key = search.order[i];
        let mut j = i;
        while j > 0 {
            let previous = search.order[j - 1];
            let previous_frequency = if global_frequency[previous] == 0 { u32::MAX } else { global_frequency[previous] };
            let key_frequency = if global_frequency[key] == 0 { u32::MAX } else { global_frequency[key] };
            if previous_frequency < key_frequency || (previous_frequency == key_frequency && previous < key) { break; }
            search.order[j] = previous;
            j -= 1;
        }
        search.order[j] = key;
    }
    find_anagrams(&mut search, phrase_mask, phrase_length as i32, 0, 0)
}
