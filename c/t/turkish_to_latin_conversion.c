#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_BYTES 1024

static int continuation(uint8_t byte) { return byte >= 0x80 && byte <= 0xBF; }

static int decode_utf8(const uint8_t *bytes, size_t length, size_t index,
                       uint32_t *codepoint, size_t *width) {
    const uint8_t first = bytes[index];
    if (first <= 0x7F) { *codepoint = first; *width = 1; return 1; }
    if (first >= 0xC2 && first <= 0xDF) {
        if (index + 1 >= length || !continuation(bytes[index + 1])) return 0;
        *codepoint = ((uint32_t)(first & 0x1F) << 6) | (bytes[index + 1] & 0x3F);
        *width = 2;
        return 1;
    }
    if (first >= 0xE0 && first <= 0xEF) {
        if (index + 2 >= length) return 0;
        const uint8_t second = bytes[index + 1], third = bytes[index + 2];
        if (!continuation(second) || !continuation(third) ||
            (first == 0xE0 && second < 0xA0) || (first == 0xED && second >= 0xA0)) return 0;
        *codepoint = ((uint32_t)(first & 0x0F) << 12) |
                     ((uint32_t)(second & 0x3F) << 6) | (third & 0x3F);
        *width = 3;
        return 1;
    }
    if (first >= 0xF0 && first <= 0xF4) {
        if (index + 3 >= length) return 0;
        const uint8_t second = bytes[index + 1], third = bytes[index + 2], fourth = bytes[index + 3];
        if (!continuation(second) || !continuation(third) || !continuation(fourth) ||
            (first == 0xF0 && second < 0x90) || (first == 0xF4 && second > 0x8F)) return 0;
        *codepoint = ((uint32_t)(first & 0x07) << 18) |
                     ((uint32_t)(second & 0x3F) << 12) |
                     ((uint32_t)(third & 0x3F) << 6) | (fourth & 0x3F);
        *width = 4;
        return 1;
    }
    return 0;
}

static uint8_t map_turkish(uint32_t codepoint) {
    switch (codepoint) {
        case 0x0131: return 'i'; case 0x0130: return 'I';
        case 0x00FC: return 'u'; case 0x00DC: return 'U';
        case 0x00F6: return 'o'; case 0x00D6: return 'O';
        case 0x015F: return 's'; case 0x015E: return 'S';
        case 0x00E7: return 'c'; case 0x00C7: return 'C';
        case 0x011F: return 'g'; case 0x011E: return 'G';
        default: return 0;
    }
}

int64_t turkish_to_latin_conversion(const int64_t *input, size_t length,
                                    uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > MAX_TEXT_BYTES + 1 ||
        input[0] < 0 || input[0] > MAX_TEXT_BYTES || length != (size_t)input[0] + 1) return -1;
    const size_t text_length = (size_t)input[0];
    uint8_t bytes[MAX_TEXT_BYTES];
    for (size_t index = 0; index < text_length; ++index) {
        if (input[index + 1] < 0 || input[index + 1] > 255) return -1;
        bytes[index] = (uint8_t)input[index + 1];
    }

    size_t result_length = 0;
    for (size_t index = 0; index < text_length;) {
        uint32_t codepoint;
        size_t width;
        if (!decode_utf8(bytes, text_length, index, &codepoint, &width)) return -1;
        result_length += map_turkish(codepoint) ? 1 : width;
        index += width;
    }
    if (result_length > output_capacity || (result_length > 0 && output == NULL)) return -2;

    size_t written = 0;
    for (size_t index = 0; index < text_length;) {
        uint32_t codepoint;
        size_t width;
        (void)decode_utf8(bytes, text_length, index, &codepoint, &width);
        const uint8_t mapped = map_turkish(codepoint);
        if (mapped) output[written++] = mapped;
        else for (size_t byte = 0; byte < width; ++byte) output[written++] = bytes[index + byte];
        index += width;
    }
    return (int64_t)result_length;
}
