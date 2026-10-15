#include <stddef.h>
#include <stdint.h>

#define MAX_WORD_LENGTH 16
#define MAX_CANDIDATES 16

static int letter(int64_t value) { return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'); }
static int lower_index(int64_t value) { return value >= 'A' && value <= 'Z' ? (int)(value - 'A') : (int)(value - 'a'); }
static int put_byte(uint8_t *output, size_t capacity, size_t *length, uint8_t value) {
    if (*length >= capacity) return 0;
    output[(*length)++] = value;
    return 1;
}

int64_t detect_anagrams(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_WORD_LENGTH) return -1;
    size_t subject_length = (size_t)input[0], offset = 1 + subject_length;
    if (offset >= length) return -1;
    for (size_t i = 0; i < subject_length; ++i) if (!letter(input[1 + i])) return -1;
    if (input[offset] < 0 || input[offset] > MAX_CANDIDATES) return -1;
    size_t candidate_count = (size_t)input[offset++];
    int subject_counts[26] = {0};
    for (size_t i = 0; i < subject_length; ++i) ++subject_counts[lower_index(input[1 + i])];
    if (output == NULL) return -2;
    size_t output_length = 0;
    int64_t matches = 0;
    for (size_t candidate = 0; candidate < candidate_count; ++candidate) {
        if (offset >= length || input[offset] < 0 || input[offset] > MAX_WORD_LENGTH) return -1;
        size_t word_length = (size_t)input[offset++];
        if (offset + word_length > length) return -1;
        int counts[26];
        for (size_t i = 0; i < 26; ++i) counts[i] = subject_counts[i];
        int identical = word_length == subject_length;
        for (size_t i = 0; i < word_length; ++i) {
            if (!letter(input[offset + i])) return -1;
            --counts[lower_index(input[offset + i])];
            if (identical && lower_index(input[offset + i]) != lower_index(input[1 + i])) identical = 0;
        }
        int same_counts = word_length == subject_length;
        for (size_t i = 0; i < 26; ++i) if (counts[i] != 0) same_counts = 0;
        if (same_counts && !identical) {
            for (size_t i = 0; i < word_length; ++i) if (!put_byte(output, capacity, &output_length, (uint8_t)input[offset + i])) return -2;
            if (!put_byte(output, capacity, &output_length, '\n')) return -2;
            ++matches;
        }
        offset += word_length;
    }
    if (offset != length) return -1;
    if (!put_byte(output, capacity, &output_length, 0)) return -2;
    return matches;
}
