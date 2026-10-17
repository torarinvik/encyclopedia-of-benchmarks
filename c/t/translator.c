#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_KEYS = 4, MAX_KEY_LENGTH = 4, MAX_TEXT_LENGTH = 64, MAX_INPUT_LENGTH = 107, MAX_OUTPUT_LENGTH = 256 };

static int printable_ascii(int64_t value) { return value >= 32 && value <= 126; }

static int same_key(const uint8_t left[4], size_t left_length,
                    const uint8_t right[4], size_t right_length) {
    return left_length == right_length && memcmp(left, right, left_length) == 0;
}

int64_t translator(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_KEYS || input[1] < 0 || input[1] > MAX_TEXT_LENGTH) return -1;
    const size_t key_count = (size_t)input[0];
    const size_t text_length = (size_t)input[1];
    uint8_t keys[MAX_KEYS][MAX_KEY_LENGTH] = {{0}}, values[MAX_KEYS][MAX_KEY_LENGTH] = {{0}};
    size_t key_lengths[MAX_KEYS] = {0}, value_lengths[MAX_KEYS] = {0};
    size_t cursor = 2;
    for (size_t key_index = 0; key_index < key_count; ++key_index) {
        if (cursor + 2 > length) return -1;
        const int64_t key_length_value = input[cursor++];
        const int64_t value_length_value = input[cursor++];
        if (key_length_value < 1 || key_length_value > MAX_KEY_LENGTH || value_length_value < 0 || value_length_value > MAX_KEY_LENGTH) return -1;
        const size_t key_length = (size_t)key_length_value;
        const size_t value_length = (size_t)value_length_value;
        if (cursor + key_length + value_length > length) return -1;
        for (size_t index = 0; index < key_length; ++index) {
            if (!printable_ascii(input[cursor + index])) return -1;
            keys[key_index][index] = (uint8_t)input[cursor + index];
        }
        cursor += key_length;
        for (size_t index = 0; index < value_length; ++index) {
            if (!printable_ascii(input[cursor + index])) return -1;
            values[key_index][index] = (uint8_t)input[cursor + index];
        }
        cursor += value_length;
        key_lengths[key_index] = key_length;
        value_lengths[key_index] = value_length;
        for (size_t previous = 0; previous < key_index; ++previous)
            if (same_key(keys[key_index], key_length, keys[previous], key_lengths[previous])) return -1;
    }
    if (cursor + text_length != length) return -1;
    uint8_t text[MAX_TEXT_LENGTH];
    for (size_t index = 0; index < text_length; ++index) {
        if (!printable_ascii(input[cursor + index])) return -1;
        text[index] = (uint8_t)input[cursor + index];
    }

    uint8_t result[MAX_OUTPUT_LENGTH];
    size_t result_length = 0, start = 0;
    while (start < text_length) {
        int matched = 0;
        const size_t maximum_length = text_length - start < MAX_KEY_LENGTH ? text_length - start : MAX_KEY_LENGTH;
        for (size_t candidate_length = 1; candidate_length <= maximum_length && !matched; ++candidate_length) {
            for (size_t key_index = 0; key_index < key_count; ++key_index) {
                if (key_lengths[key_index] != candidate_length || memcmp(text + start, keys[key_index], candidate_length) != 0) continue;
                memcpy(result + result_length, values[key_index], value_lengths[key_index]);
                result_length += value_lengths[key_index];
                start += candidate_length;
                matched = 1;
                break;
            }
        }
        if (!matched) break;
    }
    if (output == NULL || capacity < result_length) return -2;
    if (result_length != 0) memcpy(output, result, result_length);
    return (int64_t)result_length;
}
