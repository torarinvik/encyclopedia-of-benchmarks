#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 64
#define MAX_INPUT_LENGTH (MAX_TEXT_LENGTH + 1)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_INPUT_LENGTH + 2)
#define MAX_OUTPUT_BYTES 4

static int is_ascii_letter(int64_t value)
{
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

static int digit_for(int64_t value)
{
    if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
    if (value == 'a' || value == 'e' || value == 'i' || value == 'o' || value == 'u' || value == 'y') return 0;
    if (value == 'h' || value == 'w') return 8;
    if (value == 'b' || value == 'f' || value == 'p' || value == 'v') return 1;
    if (value == 'c' || value == 'g' || value == 'j' || value == 'k' || value == 'q' || value == 's' ||
        value == 'x' || value == 'z') return 2;
    if (value == 'd' || value == 't') return 3;
    if (value == 'l') return 4;
    if (value == 'm' || value == 'n') return 5;
    if (value == 'r') return 6;
    return -1;
}

int64_t soundex_encoder(const int64_t *values, size_t length,
                        uint8_t *output, size_t output_capacity)
{
    if (length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH || values == NULL) return -1;
    const int64_t text_length = values[0];
    if (text_length < 1 || text_length > MAX_TEXT_LENGTH || length > MAX_INPUT_LENGTH ||
        length != (size_t)text_length + 1) return -1;
    for (size_t index = 1; index < length; ++index)
        if (!is_ascii_letter(values[index])) return -1;

    int64_t mapped[MAX_TEXT_LENGTH];
    size_t mapped_count = 0;
    for (size_t index = 1; index < length; ++index) {
        int64_t letter = values[index];
        if (letter >= 'A' && letter <= 'Z') letter += 'a' - 'A';
        if (letter == 'h' || letter == 'w') continue;
        const int digit = digit_for(letter);
        if (mapped_count == 0 || mapped[mapped_count - 1] != digit)
            mapped[mapped_count++] = digit;
    }

    size_t code_count = 0;
    for (size_t index = 0; index < mapped_count; ++index)
        if (mapped[index] != 0) mapped[code_count++] = mapped[index];
    if (code_count == 0) return -1;

    int64_t first_letter = values[1];
    if (first_letter >= 'A' && first_letter <= 'Z') first_letter += 'a' - 'A';
    size_t start = 0;
    if (mapped[0] == digit_for(first_letter)) {
        if (code_count == 1) return -1;
        start = 1;
    }

    uint8_t encoded[MAX_OUTPUT_BYTES];
    int64_t initial = values[1];
    if (initial >= 'a' && initial <= 'z') initial -= 'a' - 'A';
    encoded[0] = (uint8_t)initial;
    for (size_t index = 0; index < 3; ++index) {
        const int64_t digit = start + index < code_count ? mapped[start + index] : 0;
        encoded[index + 1] = (uint8_t)('0' + digit);
    }

    if (output == NULL || output_capacity < MAX_OUTPUT_BYTES) return -2;
    for (size_t index = 0; index < MAX_OUTPUT_BYTES; ++index) output[index] = encoded[index];
    return MAX_OUTPUT_BYTES;
}
