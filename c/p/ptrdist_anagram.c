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

#include <stddef.h>
#include <stdint.h>

enum { MAX_PHRASE = 16, MAX_WORDS = 12, MAX_WORD_LENGTH = 16, MAX_INPUT_VALUES = 222, ALPHABET = 26 };

typedef struct {
    uint64_t mask;
    int length;
} Candidate;

typedef struct {
    Candidate candidates[MAX_WORDS];
    int candidate_count;
    int order[ALPHABET];
    uint64_t letter_mask[ALPHABET];
    uint64_t sign_mask;
} Search;

static int letter_index(int64_t value) {
    if (value >= 'a' && value <= 'z') return (int)(value - 'a');
    if (value >= 'A' && value <= 'Z') return (int)(value - 'A');
    return -1;
}

static int64_t find_anagrams(Search *search, uint64_t remaining_mask, int remaining_length,
                             int start, int first_letter) {
    if (remaining_length == 0) return 1;
    int pivot_position = first_letter;
    while (pivot_position < ALPHABET) {
        const int letter = search->order[pivot_position];
        if ((remaining_mask & search->letter_mask[letter]) != 0) break;
        ++pivot_position;
    }
    if (pivot_position == ALPHABET) return 0;
    const int pivot = search->order[pivot_position];
    int end = search->candidate_count;
    int64_t solutions = 0;
    while (start < end) {
        const Candidate candidate = search->candidates[start];
        const uint64_t after = remaining_mask - candidate.mask;
        if ((after & search->sign_mask) != 0) {
            ++start;
            continue;
        }
        if ((candidate.mask & search->letter_mask[pivot]) == 0) {
            search->candidates[start] = search->candidates[end - 1];
            search->candidates[end - 1] = candidate;
            --end;
            continue;
        }
        const int next_length = remaining_length - candidate.length;
        solutions += next_length == 0
            ? 1
            : find_anagrams(search, after, next_length, start, pivot_position);
        ++start;
    }
    return solutions;
}

int64_t ptrdist_anagram(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > MAX_PHRASE) return -1;
    const size_t phrase_length = (size_t)input[0];
    const size_t count_offset = phrase_length + 1;
    if (count_offset >= length || input[count_offset] < 0 || input[count_offset] > MAX_WORDS) return -1;
    uint8_t phrase_counts[ALPHABET] = {0};
    for (size_t i = 0; i < phrase_length; ++i) {
        const int letter = letter_index(input[i + 1]);
        if (letter < 0) return -1;
        ++phrase_counts[letter];
    }

    const size_t word_count = (size_t)input[count_offset];
    size_t offset = count_offset + 1;
    uint64_t phrase_mask = 0;
    uint64_t sign_mask = 0;
    uint64_t letter_mask[ALPHABET] = {0};
    unsigned letter_shift[ALPHABET] = {0};
    unsigned global_frequency[ALPHABET] = {0};
    unsigned shift = 0;
    for (int letter = 0; letter < ALPHABET; ++letter) {
        const unsigned frequency = phrase_counts[letter];
        if (frequency == 0) continue;
        unsigned count_bits = 1;
        while ((1u << count_bits) <= frequency) ++count_bits;
        if (shift + count_bits + 1 > 64) return -1;
        const uint64_t field = ((UINT64_C(1) << count_bits) - 1) << shift;
        const uint64_t sign = UINT64_C(1) << (shift + count_bits);
        letter_mask[letter] = field;
        letter_shift[letter] = shift;
        phrase_mask |= (uint64_t)frequency << shift;
        sign_mask |= sign;
        shift += count_bits + 1;
    }

    Search search = {0};
    search.sign_mask = sign_mask;
    for (int letter = 0; letter < ALPHABET; ++letter) search.letter_mask[letter] = letter_mask[letter];
    for (size_t word_index = 0; word_index < word_count; ++word_index) {
        if (offset >= length || input[offset] < 1 || input[offset] > MAX_WORD_LENGTH) return -1;
        const size_t word_length = (size_t)input[offset++];
        if (word_length > length - offset) return -1;
        uint8_t counts[ALPHABET] = {0};
        for (size_t i = 0; i < word_length; ++i) {
            const int letter = letter_index(input[offset + i]);
            if (letter < 0) return -1;
            ++counts[letter];
        }
        int fits = 1;
        for (int letter = 0; letter < ALPHABET; ++letter) {
            if (counts[letter] > phrase_counts[letter]) fits = 0;
        }
        if (fits && (((word_length >= 2 && word_length + 2 <= phrase_length) || word_length == phrase_length))) {
            if (search.candidate_count >= MAX_WORDS) return -1;
            uint64_t word_mask = 0;
            for (int letter = 0; letter < ALPHABET; ++letter) {
                word_mask |= (uint64_t)counts[letter] << letter_shift[letter];
                global_frequency[letter] += counts[letter];
            }
            search.candidates[search.candidate_count++] = (Candidate){word_mask, (int)word_length};
        }
        offset += word_length;
    }
    if (offset != length) return -1;

    for (int letter = 0; letter < ALPHABET; ++letter) search.order[letter] = letter;
    for (int i = 1; i < ALPHABET; ++i) {
        const int key = search.order[i];
        int j = i;
        while (j > 0) {
            const int previous = search.order[j - 1];
            const unsigned previous_frequency = global_frequency[previous] == 0 ? UINT32_MAX : global_frequency[previous];
            const unsigned key_frequency = global_frequency[key] == 0 ? UINT32_MAX : global_frequency[key];
            if (previous_frequency < key_frequency ||
                (previous_frequency == key_frequency && previous < key)) break;
            search.order[j] = previous;
            --j;
        }
        search.order[j] = key;
    }
    return find_anagrams(&search, phrase_mask, (int)phrase_length, 0, 0);
}
