#include <stddef.h>
#include <stdint.h>

enum { MAX_CARDS = 12, MAX_INPUT_WORDS = 14, DECK_SIZE = 81 };

static int complement_code(int a, int b) {
    int result = 0;
    int place = 1;
    for (int feature = 0; feature < 4; ++feature) {
        const int digit_sum = (a / place) % 3 + (b / place) % 3;
        result += ((3 - digit_sum % 3) % 3) * place;
        place *= 3;
    }
    return result;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t set_puzzle_find_sets(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_WORDS) return -1;
    const int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > MAX_CARDS ||
        length != (size_t)raw_count + 1) return -1;

    int8_t index_by_code[DECK_SIZE];
    int8_t code_by_index[MAX_CARDS];
    for (size_t code = 0; code < DECK_SIZE; ++code) index_by_code[code] = -1;
    const size_t count = (size_t)raw_count;
    for (size_t i = 0; i < count; ++i) {
        const int64_t code = input[i + 1];
        if (code < 0 || code >= DECK_SIZE || index_by_code[code] >= 0) return -1;
        index_by_code[code] = (int8_t)i;
        code_by_index[i] = (int8_t)code;
    }

    size_t set_count = 0;
    for (size_t i = 0; i < count; ++i) {
        for (size_t j = i + 1; j < count; ++j) {
            const int complement = complement_code(code_by_index[i], code_by_index[j]);
            const int k = index_by_code[complement];
            if (k > (int)j) ++set_count;
        }
    }

    const size_t output_bytes = (1 + 3 * set_count) * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    put_i64_le(output, 0, (int64_t)set_count);
    size_t output_word = 1;
    for (size_t i = 0; i < count; ++i) {
        for (size_t j = i + 1; j < count; ++j) {
            const int complement = complement_code(code_by_index[i], code_by_index[j]);
            const int k = index_by_code[complement];
            if (k > (int)j) {
                put_i64_le(output, output_word++ * 8, (int64_t)i);
                put_i64_le(output, output_word++ * 8, (int64_t)j);
                put_i64_le(output, output_word++ * 8, (int64_t)k);
            }
        }
    }
    return (int64_t)output_bytes;
}
