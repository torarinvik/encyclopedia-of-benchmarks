#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 256
#define MAX_PARSEABLE_LENGTH (MAX_TEXT_LENGTH + 2)
#define HASH_CODE 35

int64_t move_hash_to_end(const int64_t *values, size_t length,
                         uint8_t *output, size_t capacity) {
    if (values == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t text_length = values[0];
    if (text_length < 0 || text_length > MAX_TEXT_LENGTH || length != (size_t)text_length + 1) return -1;
    for (size_t i = 0; i < (size_t)text_length; ++i)
        if (values[i + 1] < 0 || values[i + 1] > 127) return -1;
    if (capacity < (size_t)text_length || (text_length > 0 && output == NULL)) return -2;
    size_t position = 0;
    for (size_t i = 0; i < (size_t)text_length; ++i)
        if (values[i + 1] != HASH_CODE) output[position++] = (uint8_t)values[i + 1];
    while (position < (size_t)text_length) output[position++] = HASH_CODE;
    return text_length;
}
