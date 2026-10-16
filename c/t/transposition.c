#include <stddef.h>
#include <stdint.h>

#define MAX_KEY 32
#define MAX_TEXT 512
#define MAX_INPUT (3 + MAX_KEY + MAX_TEXT)
#define MAX_PADDED (MAX_TEXT + MAX_KEY)

static int ascii_letter(int64_t value)
{
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

static uint64_t hash_output(const uint8_t *text, size_t length)
{
    uint64_t hash = UINT64_C(14695981039346656037);
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash = (hash ^ ((uint64_t)length >> (8 * byte) & UINT64_C(255))) * UINT64_C(1099511628211);
    }
    for (size_t index = 0; index < length; ++index) {
        uint32_t codepoint = text[index];
        for (unsigned byte = 0; byte < 4; ++byte) {
            hash = (hash ^ ((uint64_t)codepoint >> (8 * byte) & UINT64_C(255))) * UINT64_C(1099511628211);
        }
    }
    return hash & UINT64_C(0x7fffffffffffffff);
}

int64_t transposition(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t mode = input[0], key_length_value = input[1];
    if ((mode != 0 && mode != 1) || key_length_value < 1 || key_length_value > MAX_KEY) return -1;
    const size_t key_length = (size_t)key_length_value;
    const size_t text_length_index = 2 + key_length;
    if (length <= text_length_index) return -1;
    const int64_t text_length_value = input[text_length_index];
    if (text_length_value < 1 || text_length_value > MAX_TEXT) return -1;
    const size_t text_length = (size_t)text_length_value;
    if (length != text_length_index + 1 + text_length) return -1;

    uint8_t key[MAX_KEY], sorted[MAX_KEY], text[MAX_PADDED], result[MAX_PADDED];
    for (size_t index = 0; index < key_length; ++index) {
        const int64_t value = input[2 + index];
        if (!ascii_letter(value)) return -1;
        uint8_t ch = (uint8_t)value;
        if (ch >= 'A' && ch <= 'Z') ch = (uint8_t)(ch + ('a' - 'A'));
        key[index] = sorted[index] = ch;
    }
    for (size_t index = 1; index < key_length; ++index) {
        const uint8_t value = sorted[index];
        size_t cursor = index;
        while (cursor > 0 && sorted[cursor - 1] > value) {
            sorted[cursor] = sorted[cursor - 1];
            --cursor;
        }
        sorted[cursor] = value;
    }
    size_t ranks[MAX_KEY];
    for (size_t index = 0; index < key_length; ++index) {
        size_t first = 0, duplicate = 0;
        while (first < key_length && sorted[first] != key[index]) ++first;
        for (size_t prior = 0; prior < index; ++prior) if (key[prior] == key[index]) ++duplicate;
        ranks[index] = first + duplicate + 1;
    }

    for (size_t index = 0; index < text_length; ++index) {
        const int64_t value = input[text_length_index + 1 + index];
        if (value < 32 || value > 126) return -1;
        text[index] = (uint8_t)value;
    }
    if (mode == 0 && text[text_length - 1] == ' ') return -1;
    const size_t padding = key_length - text_length % key_length;
    const size_t padded_length = text_length + padding;
    for (size_t index = text_length; index < padded_length; ++index) text[index] = ' ';

    size_t result_length = 0;
    if (mode == 0) {
        for (size_t start = 0; start < padded_length; start += key_length) {
            uint8_t block[MAX_KEY];
            for (size_t offset = 0; offset < key_length; ++offset)
                block[ranks[offset] - 1] = text[start + offset];
            for (size_t offset = 0; offset < key_length; ++offset) result[result_length++] = block[offset];
        }
    } else {
        for (size_t start = 0; start < text_length; start += key_length) {
            for (size_t offset = 0; offset < key_length; ++offset)
                result[result_length++] = text[start + ranks[offset] - 1];
        }
        while (result_length > 0 && result[result_length - 1] == ' ') --result_length;
    }
    return (int64_t)hash_output(result, result_length);
}
