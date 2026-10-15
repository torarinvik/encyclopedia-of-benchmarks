#include <stddef.h>
#include <stdint.h>

#define MAX_WORDS 100
#define MAX_WORD_LENGTH 20
#define MAX_INPUT_LENGTH 2127
#define INVALID_RESULT INT64_C(-1)

int64_t verifying_an_alien_dictionary(const int64_t *input, size_t length)
{
    if (input == NULL || length < 27 || length > MAX_INPUT_LENGTH || input[0] < 1 || input[0] > MAX_WORDS)
        return INVALID_RESULT;
    const size_t word_count = (size_t)input[0];
    int64_t rank[26];
    uint8_t order_seen[26] = {0};
    for (size_t position = 0; position < 26; ++position) {
        const int64_t letter = input[1 + position];
        if (letter < 'a' || letter > 'z') return INVALID_RESULT;
        const size_t index = (size_t)(letter - 'a');
        if (order_seen[index]) return INVALID_RESULT;
        order_seen[index] = 1;
        rank[index] = (int64_t)position;
    }

    size_t starts[MAX_WORDS], word_lengths[MAX_WORDS];
    size_t offset = 27;
    for (size_t word = 0; word < word_count; ++word) {
        if (offset >= length || input[offset] < 1 || input[offset] > MAX_WORD_LENGTH)
            return INVALID_RESULT;
        const size_t word_length = (size_t)input[offset++];
        if (word_length > length - offset) return INVALID_RESULT;
        starts[word] = offset;
        word_lengths[word] = word_length;
        for (size_t character = 0; character < word_length; ++character)
            if (input[offset + character] < 'a' || input[offset + character] > 'z')
                return INVALID_RESULT;
        offset += word_length;
    }
    if (offset != length) return INVALID_RESULT;

    for (size_t word = 0; word + 1 < word_count; ++word) {
        const size_t left_length = word_lengths[word];
        const size_t right_length = word_lengths[word + 1];
        const size_t limit = left_length < right_length ? left_length : right_length;
        int decided = 0;
        for (size_t character = 0; character < limit; ++character) {
            const size_t left_letter = (size_t)(input[starts[word] + character] - 'a');
            const size_t right_letter = (size_t)(input[starts[word + 1] + character] - 'a');
            if (rank[left_letter] < rank[right_letter]) {
                decided = 1;
                break;
            }
            if (rank[left_letter] > rank[right_letter]) return 0;
        }
        if (!decided && left_length > right_length) return 0;
    }
    return 1;
}
