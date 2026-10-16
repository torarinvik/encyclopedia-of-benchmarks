#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 256
#define MAX_INPUT_LENGTH (MAX_TEXT_LENGTH + 1)
#define LETTER_COUNT 26
#define BYTES_PER_RECORD 8
#define BYTES_PER_I32 4

static void store_i32_le(uint8_t *output, size_t position, int64_t value) {
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < BYTES_PER_I32; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

extern "C" int64_t unique_letters_count(const int64_t *input, size_t length,
                                         uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_TEXT_LENGTH ||
        length != 1 + (size_t)input[0]) return -1;

    const size_t text_length = (size_t)input[0];
    for (size_t index = 0; index < text_length; ++index)
        if (input[index + 1] < 0 || input[index + 1] > 127) return -1;

    int32_t frequencies[LETTER_COUNT] = {0};
    int32_t first_seen[LETTER_COUNT] = {0};
    size_t unique_count = 0;
    for (size_t index = 0; index < text_length; ++index) {
        int64_t byte = input[index + 1];
        if (byte >= 'A' && byte <= 'Z') byte += 'a' - 'A';
        else if (byte < 'a' || byte > 'z') continue;
        const size_t letter_index = (size_t)(byte - 'a');
        if (frequencies[letter_index] == 0)
            first_seen[unique_count++] = (int32_t)byte;
        ++frequencies[letter_index];
    }

    const size_t maximum_result = text_length < LETTER_COUNT ? text_length : LETTER_COUNT;
    const size_t required_capacity = maximum_result * BYTES_PER_RECORD;
    if (output_capacity < required_capacity || (required_capacity > 0 && output == NULL)) return -2;

    for (size_t index = 0; index < unique_count; ++index) {
        const int32_t letter = first_seen[index];
        store_i32_le(output, index * BYTES_PER_RECORD, letter);
        store_i32_le(output, index * BYTES_PER_RECORD + BYTES_PER_I32,
                     frequencies[(size_t)(letter - 'a')]);
    }
    return (int64_t)unique_count;
}
