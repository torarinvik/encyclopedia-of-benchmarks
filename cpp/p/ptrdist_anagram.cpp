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

#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_phrase = 16, max_words = 12, max_word_length = 16, alphabet = 26;
struct Candidate { std::uint64_t mask; int length; };
struct Search {
    std::array<Candidate, max_words> candidates{};
    int candidate_count = 0;
    std::array<int, alphabet> order{};
    std::array<std::uint64_t, alphabet> letter_mask{};
    std::uint64_t sign_mask = 0;
};

int letter_index(std::int64_t value) {
    if (value >= 'a' && value <= 'z') return static_cast<int>(value - 'a');
    if (value >= 'A' && value <= 'Z') return static_cast<int>(value - 'A');
    return -1;
}

std::int64_t find_anagrams(Search &search, std::uint64_t remaining_mask, int remaining_length,
                           int start, int first_letter) {
    if (remaining_length == 0) return 1;
    int pivot_position = first_letter;
    while (pivot_position < alphabet) {
        const int letter = search.order[pivot_position];
        if ((remaining_mask & search.letter_mask[letter]) != 0) break;
        ++pivot_position;
    }
    if (pivot_position == alphabet) return 0;
    const int pivot = search.order[pivot_position];
    int end = search.candidate_count;
    std::int64_t solutions = 0;
    while (start < end) {
        const Candidate candidate = search.candidates[start];
        const std::uint64_t after = remaining_mask - candidate.mask;
        if ((after & search.sign_mask) != 0) { ++start; continue; }
        if ((candidate.mask & search.letter_mask[pivot]) == 0) {
            search.candidates[start] = search.candidates[end - 1];
            search.candidates[end - 1] = candidate;
            --end;
            continue;
        }
        const int next_length = remaining_length - candidate.length;
        solutions += next_length == 0 ? 1 : find_anagrams(search, after, next_length, start, pivot_position);
        ++start;
    }
    return solutions;
}
}

extern "C" std::int64_t ptrdist_anagram(const std::int64_t *input, std::size_t length) {
    constexpr std::size_t max_input_values = 222;
    if (input == nullptr || length < 3 || length > max_input_values || input[0] < 1 || input[0] > max_phrase) return -1;
    const std::size_t phrase_length = static_cast<std::size_t>(input[0]);
    const std::size_t count_offset = phrase_length + 1;
    if (count_offset >= length || input[count_offset] < 0 || input[count_offset] > max_words) return -1;
    std::array<std::uint8_t, alphabet> phrase_counts{};
    for (std::size_t i = 0; i < phrase_length; ++i) {
        const int letter = letter_index(input[i + 1]);
        if (letter < 0) return -1;
        ++phrase_counts[letter];
    }

    const std::size_t word_count = static_cast<std::size_t>(input[count_offset]);
    std::size_t offset = count_offset + 1;
    std::uint64_t phrase_mask = 0, sign_mask = 0;
    std::array<std::uint64_t, alphabet> letter_mask{};
    std::array<unsigned, alphabet> letter_shift{}, global_frequency{};
    unsigned shift = 0;
    for (int letter = 0; letter < alphabet; ++letter) {
        const unsigned frequency = phrase_counts[letter];
        if (frequency == 0) continue;
        unsigned count_bits = 1;
        while ((1u << count_bits) <= frequency) ++count_bits;
        if (shift + count_bits + 1 > 64) return -1;
        letter_mask[letter] = ((std::uint64_t{1} << count_bits) - 1) << shift;
        phrase_mask |= static_cast<std::uint64_t>(frequency) << shift;
        sign_mask |= std::uint64_t{1} << (shift + count_bits);
        letter_shift[letter] = shift;
        shift += count_bits + 1;
    }

    Search search{};
    search.sign_mask = sign_mask;
    search.letter_mask = letter_mask;
    for (std::size_t word_index = 0; word_index < word_count; ++word_index) {
        if (offset >= length || input[offset] < 1 || input[offset] > max_word_length) return -1;
        const std::size_t word_length = static_cast<std::size_t>(input[offset++]);
        if (word_length > length - offset) return -1;
        std::array<std::uint8_t, alphabet> counts{};
        for (std::size_t i = 0; i < word_length; ++i) {
            const int letter = letter_index(input[offset + i]);
            if (letter < 0) return -1;
            ++counts[letter];
        }
        bool fits = true;
        for (int letter = 0; letter < alphabet; ++letter)
            if (counts[letter] > phrase_counts[letter]) fits = false;
        if (fits && ((word_length >= 2 && word_length + 2 <= phrase_length) || word_length == phrase_length)) {
            std::uint64_t mask = 0;
            for (int letter = 0; letter < alphabet; ++letter) {
                mask |= static_cast<std::uint64_t>(counts[letter]) << letter_shift[letter];
                global_frequency[letter] += counts[letter];
            }
            search.candidates[search.candidate_count++] = {mask, static_cast<int>(word_length)};
        }
        offset += word_length;
    }
    if (offset != length) return -1;

    for (int letter = 0; letter < alphabet; ++letter) search.order[letter] = letter;
    for (int i = 1; i < alphabet; ++i) {
        const int key = search.order[i];
        int j = i;
        while (j > 0) {
            const int previous = search.order[j - 1];
            const unsigned previous_frequency = global_frequency[previous] == 0 ? UINT32_MAX : global_frequency[previous];
            const unsigned key_frequency = global_frequency[key] == 0 ? UINT32_MAX : global_frequency[key];
            if (previous_frequency < key_frequency || (previous_frequency == key_frequency && previous < key)) break;
            search.order[j] = previous;
            --j;
        }
        search.order[j] = key;
    }
    return find_anagrams(search, phrase_mask, static_cast<int>(phrase_length), 0, 0);
}
