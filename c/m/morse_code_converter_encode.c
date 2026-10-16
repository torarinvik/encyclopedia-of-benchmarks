#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_INPUT_LENGTH 512
#define MAX_OUTPUT_BYTES 2560
static const char *const MORSE[26] = {
    ".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---",
    "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-",
    "..-", "...-", ".--", "-..-", "-.--", "--.."
};

static int letter_index(int64_t value) {
    if (value >= 'A' && value <= 'Z') return (int)(value - 'A');
    if (value >= 'a' && value <= 'z') return (int)(value - 'a');
    return -1;
}

static void append_word(const int64_t *text, size_t start, size_t end,
                        uint8_t *scratch, size_t *written) {
    for (size_t position = start; position < end; ++position) {
        int index = letter_index(text[position]);
        if (index >= 0) {
            const char *code = MORSE[index];
            while (*code != '\0') scratch[(*written)++] = (uint8_t)*code++;
        }
        scratch[(*written)++] = ' ';
    }
}

static size_t encode_text(const int64_t *text, size_t length, uint8_t *scratch) {
    size_t end = length;
    while (end > 0 && text[end - 1] == ' ') --end;
    if (end == 0) return 0;
    size_t written = 0, start = 0;
    for (size_t position = 0; position <= end; ++position) {
        if (position == end || text[position] == ' ') {
            append_word(text, start, position, scratch, &written);
            if (position < end) { scratch[written++] = '|'; scratch[written++] = ' '; }
            start = position + 1;
        }
    }
    while (written > 0 && scratch[written - 1] == ' ') --written;
    return written;
}

int64_t morse_code_converter_encode(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if ((input == NULL && length != 0) || length > MAX_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;
    uint8_t scratch[MAX_OUTPUT_BYTES];
    size_t written = encode_text(input, length, scratch);
    if (output == NULL || capacity < written) return -2;
    if (written != 0) memcpy(output, scratch, written);
    return (int64_t)written;
}
