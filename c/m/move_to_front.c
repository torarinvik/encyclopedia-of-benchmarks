#include <stddef.h>
#include <stdint.h>

#define MAX_ALPHABET_LENGTH 32
#define MAX_TEXT_LENGTH 128
#define MAX_PARSEABLE_LENGTH 164

int64_t move_to_front(const int64_t *values, size_t length,
                      uint8_t *output, size_t capacity) {
    if (values == NULL || length < 3 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t mode = values[0];
    const int64_t alphabet_length = values[1];
    const int64_t text_length = values[2];
    if ((mode != 0 && mode != 1) || alphabet_length < 0 || alphabet_length > MAX_ALPHABET_LENGTH
        || text_length < 0 || text_length > MAX_TEXT_LENGTH
        || length != 3 + (size_t)alphabet_length + (size_t)text_length) return -1;

    int64_t alphabet[MAX_ALPHABET_LENGTH];
    uint8_t result[MAX_TEXT_LENGTH];
    for (size_t i = 0; i < (size_t)alphabet_length; ++i) {
        const int64_t symbol = values[3 + i];
        if (symbol < 0 || symbol > 127) return -1;
        for (size_t j = 0; j < i; ++j) if (alphabet[j] == symbol) return -1;
        alphabet[i] = symbol;
    }

    size_t result_length = 0;
    if (mode == 0) {
        if (text_length > 0 && alphabet_length == 0) return -1;
        for (size_t i = 0; i < (size_t)text_length; ++i) {
            const int64_t symbol = values[3 + (size_t)alphabet_length + i];
            if (symbol < 0 || symbol > 127) return -1;
            size_t position = 0;
            while (position < (size_t)alphabet_length && alphabet[position] != symbol) ++position;
            if (position == (size_t)alphabet_length) return -1;
            result[result_length++] = (uint8_t)position;
            while (position > 0) { alphabet[position] = alphabet[position - 1]; --position; }
            alphabet[0] = symbol;
        }
    } else if (alphabet_length > 0) {
        for (size_t i = 0; i < (size_t)text_length; ++i) {
            const int64_t index = values[3 + (size_t)alphabet_length + i];
            if (index < 0 || index >= alphabet_length) return -1;
            const int64_t symbol = alphabet[index];
            result[result_length++] = (uint8_t)symbol;
            for (size_t j = (size_t)index; j > 0; --j) alphabet[j] = alphabet[j - 1];
            alphabet[0] = symbol;
        }
    }

    if (capacity < result_length || (result_length > 0 && output == NULL)) return -2;
    for (size_t i = 0; i < result_length; ++i) output[i] = result[i];
    return (int64_t)result_length;
}
