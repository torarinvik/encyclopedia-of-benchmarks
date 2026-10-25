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

module ptrdist_anagram;

const int MAX_PHRASE = 16;
const int MAX_WORDS = 12;
const int MAX_WORD_LENGTH = 16;
const int ALPHABET = 26;

struct Candidate { ulong mask; int length; }
struct Search {
    Candidate[12] candidates;
    int candidate_count;
    int[26] order;
    ulong[26] letter_mask;
    ulong sign_mask;
}

fn int letter_index(long value) {
    if (value >= 'a' && value <= 'z') return (int)(value - 'a');
    if (value >= 'A' && value <= 'Z') return (int)(value - 'A');
    return -1;
}

fn long find_anagrams(Search* search, ulong remaining_mask, int remaining_length, int start, int first_letter) {
    if (remaining_length == 0) return 1;
    int pivot_position = first_letter;
    while (pivot_position < ALPHABET) {
        int letter = search->order[pivot_position];
        if ((remaining_mask & search->letter_mask[letter]) != 0) break;
        pivot_position++;
    }
    if (pivot_position == ALPHABET) return 0;
    int pivot = search->order[pivot_position];
    int end = search->candidate_count;
    long solutions = 0;
    while (start < end) {
        Candidate candidate = search->candidates[start];
        ulong after = remaining_mask - candidate.mask;
        if ((after & search->sign_mask) != 0) { start++; continue; }
        if ((candidate.mask & search->letter_mask[pivot]) == 0) {
            search->candidates[start] = search->candidates[end - 1];
            search->candidates[end - 1] = candidate;
            end--;
            continue;
        }
        int next_length = remaining_length - candidate.length;
        solutions += next_length == 0 ? 1 : find_anagrams(search, after, next_length, start, pivot_position);
        start++;
    }
    return solutions;
}

fn long ptrdist_anagram(long* input, usz length) @export("ptrdist_anagram") {
    if (input == null || length < 3 || length > 222 || input[0] < 1 || input[0] > MAX_PHRASE) return -1;
    usz phrase_length = (usz)input[0];
    usz count_offset = phrase_length + 1;
    if (count_offset >= length || input[count_offset] < 0 || input[count_offset] > MAX_WORDS) return -1;
    uchar[26] phrase_counts = {};
    for (usz i = 0; i < phrase_length; i++) {
        int letter = letter_index(input[i + 1]);
        if (letter < 0) return -1;
        phrase_counts[letter]++;
    }

    usz word_count = (usz)input[count_offset];
    usz offset = count_offset + 1;
    ulong phrase_mask = 0, sign_mask = 0;
    ulong[26] letter_mask = {};
    uint[26] letter_shift = {}, global_frequency = {};
    uint shift = 0;
    for (int letter = 0; letter < ALPHABET; letter++) {
        uint frequency = phrase_counts[letter];
        if (frequency == 0) continue;
        uint count_bits = 1;
        while ((1u << count_bits) <= frequency) count_bits++;
        if (shift + count_bits + 1 > 64) return -1;
        letter_mask[letter] = (((ulong)1 << count_bits) - 1) << shift;
        phrase_mask |= (ulong)frequency << shift;
        sign_mask |= (ulong)1 << (shift + count_bits);
        letter_shift[letter] = shift;
        shift += count_bits + 1;
    }

    Search search = {};
    search.sign_mask = sign_mask;
    for (int letter = 0; letter < ALPHABET; letter++) search.letter_mask[letter] = letter_mask[letter];
    for (usz word_index = 0; word_index < word_count; word_index++) {
        if (offset >= length || input[offset] < 1 || input[offset] > MAX_WORD_LENGTH) return -1;
        usz word_length = (usz)input[offset++];
        if (word_length > length - offset) return -1;
        uchar[26] counts = {};
        for (usz i = 0; i < word_length; i++) {
            int letter = letter_index(input[offset + i]);
            if (letter < 0) return -1;
            counts[letter]++;
        }
        bool fits = true;
        for (int letter = 0; letter < ALPHABET; letter++) if (counts[letter] > phrase_counts[letter]) fits = false;
        if (fits && ((word_length >= 2 && word_length + 2 <= phrase_length) || word_length == phrase_length)) {
            ulong mask = 0;
            for (int letter = 0; letter < ALPHABET; letter++) {
                mask |= (ulong)counts[letter] << letter_shift[letter];
                global_frequency[letter] += counts[letter];
            }
            search.candidates[search.candidate_count++] = Candidate{mask, (int)word_length};
        }
        offset += word_length;
    }
    if (offset != length) return -1;

    for (int letter = 0; letter < ALPHABET; letter++) search.order[letter] = letter;
    for (int i = 1; i < ALPHABET; i++) {
        int key = search.order[i], j = i;
        while (j > 0) {
            int previous = search.order[j - 1];
            uint previous_frequency = global_frequency[previous] == 0 ? 0xffffffff : global_frequency[previous];
            uint key_frequency = global_frequency[key] == 0 ? 0xffffffff : global_frequency[key];
            if (previous_frequency < key_frequency || (previous_frequency == key_frequency && previous < key)) break;
            search.order[j] = previous;
            j--;
        }
        search.order[j] = key;
    }
    return find_anagrams(&search, phrase_mask, (int)phrase_length, 0, 0);
}
