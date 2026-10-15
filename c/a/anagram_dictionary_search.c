#include <stddef.h>
#include <stdint.h>

#define MAX_WORDS 16
#define MAX_WORD_LENGTH 16

static int is_anagram(const int64_t *query, size_t query_length, const int64_t *word, size_t word_length) {
    if (query_length != word_length) return 0;
    int counts[26] = {0};
    for (size_t i = 0; i < query_length; ++i) { ++counts[query[i] - 'a']; --counts[word[i] - 'a']; }
    for (size_t i = 0; i < 26; ++i) if (counts[i] != 0) return 0;
    return 1;
}

int64_t anagram_dictionary_search(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_WORDS || input[1] < 0 || input[1] > MAX_WORD_LENGTH) return -1;
    const size_t word_count = (size_t)input[0], query_length = (size_t)input[1];
    if (2 + query_length > length) return -1;
    for (size_t i = 0; i < query_length; ++i) if (input[2 + i] < 'a' || input[2 + i] > 'z') return -1;
    if (output == NULL) return -2;
    size_t offset = 2 + query_length, out = 0;
    for (size_t item = 0; item < word_count; ++item) {
        if (offset >= length || input[offset] < 1 || input[offset] > MAX_WORD_LENGTH) return -1;
        const size_t word_length = (size_t)input[offset++];
        if (offset + word_length > length) return -1;
        for (size_t i = 0; i < word_length; ++i) if (input[offset + i] < 'a' || input[offset + i] > 'z') return -1;
        if (is_anagram(input + 2, query_length, input + offset, word_length)) {
            for (size_t i = 0; i < word_length; ++i) { if (out >= capacity) return -2; output[out++] = (uint8_t)input[offset + i]; }
            if (out >= capacity) return -2;
            output[out++] = '\n';
        }
        offset += word_length;
    }
    if (offset != length || out >= capacity) return offset == length ? -2 : -1;
    output[out++] = 0;
    return (int64_t)out;
}
