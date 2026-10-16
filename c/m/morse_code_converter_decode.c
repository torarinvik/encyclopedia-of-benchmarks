#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 512
#define MAX_OUTPUT_BYTES 512
static const char *const MORSE[26] = {
    ".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---",
    "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-",
    "..-", "...-", ".--", "-..-", "-.--", "--.."
};

static int is_separator(const int64_t *text, size_t position, size_t end) {
    return position + 2 < end && text[position] == ' ' &&
        text[position + 1] == '|' && text[position + 2] == ' ';
}

static uint8_t decode_token(const int64_t *text, size_t start, size_t end) {
    for (size_t letter = 0; letter < 26; ++letter) {
        size_t code_length = 0;
        while (MORSE[letter][code_length] != '\0') ++code_length;
        if (end - start != code_length) continue;
        size_t offset = 0;
        while (offset < code_length && text[start + offset] == (uint8_t)MORSE[letter][offset]) ++offset;
        if (offset == code_length) return (uint8_t)('A' + letter);
    }
    return '?';
}

static void append_word(const int64_t *text, size_t start, size_t end,
                        uint8_t *scratch, size_t *written) {
    if (start == end) { scratch[(*written)++] = '?'; return; }
    while (end > start && text[end - 1] == ' ') --end;
    if (start == end) return;
    size_t token_start = start;
    for (size_t position = start; position <= end; ++position) {
        if (position == end || text[position] == ' ') {
            scratch[(*written)++] = decode_token(text, token_start, position);
            token_start = position + 1;
        }
    }
}

static size_t decode_morse(const int64_t *text, size_t length, uint8_t *scratch) {
    if (length == 0) { scratch[0] = '?'; return 1; }
    size_t end = length;
    while (end >= 3 && is_separator(text, end - 3, end)) end -= 3;
    if (end == 0) return 0;
    size_t written = 0, start = 0, position = 0;
    while (position + 2 < end) {
        if (is_separator(text, position, end)) {
            append_word(text, start, position, scratch, &written);
            scratch[written++] = ' ';
            position += 3;
            start = position;
        } else ++position;
    }
    append_word(text, start, end, scratch, &written);
    return written;
}

int64_t morse_code_converter_decode(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if ((input == NULL && length != 0) || length > MAX_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;
    uint8_t scratch[MAX_OUTPUT_BYTES];
    size_t written = decode_morse(input, length, scratch);
    if (output == NULL || capacity < written) return -2;
    for (size_t index = 0; index < written; ++index) output[index] = scratch[index];
    return (int64_t)written;
}
