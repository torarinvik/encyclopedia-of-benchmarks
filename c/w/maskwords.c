#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_BYTES 512
#define MAX_MASK_BYTES 16
#define MAX_PARSEABLE_INPUT_LENGTH 531
#define MAX_OUTPUT_BYTES 1447

static int is_word(uint8_t value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') ||
           (value >= '0' && value <= '9') || value == '_';
}

static int is_normalized_target(const uint8_t *text, size_t start, size_t end) {
    const size_t length = end - start;
    if (length == 5) {
        return (text[start] == 'b' && text[start + 1] == 'i' &&
                text[start + 2] == 'r' && text[start + 3] == 'd' &&
                text[start + 4] == 's') ||
               (text[start] == 'B' && text[start + 1] == 'I' &&
                text[start + 2] == 'R' && text[start + 3] == 'D' &&
                text[start + 4] == 'S') ||
               (text[start] == 'B' && text[start + 1] == 'i' &&
                text[start + 2] == 'r' && text[start + 3] == 'd' &&
                text[start + 4] == 's');
    }
    if (length == 6) {
        return (text[start] == 'm' && text[start + 1] == 'a' &&
                text[start + 2] == 'r' && text[start + 3] == 'k' &&
                text[start + 4] == 'e' && text[start + 5] == 't') ||
               (text[start] == 'M' && text[start + 1] == 'A' &&
                text[start + 2] == 'R' && text[start + 3] == 'K' &&
                text[start + 4] == 'E' && text[start + 5] == 'T') ||
               (text[start] == 'M' && text[start + 1] == 'a' &&
                text[start + 2] == 'r' && text[start + 3] == 'k' &&
                text[start + 4] == 'e' && text[start + 5] == 't') ||
               (text[start] == 's' && text[start + 1] == 't' &&
                text[start + 2] == 'r' && text[start + 3] == 'e' &&
                text[start + 4] == 'e' && text[start + 5] == 't') ||
               (text[start] == 'S' && text[start + 1] == 'T' &&
                text[start + 2] == 'R' && text[start + 3] == 'E' &&
                text[start + 4] == 'E' && text[start + 5] == 'T') ||
               (text[start] == 'S' && text[start + 1] == 't' &&
                text[start + 2] == 'r' && text[start + 3] == 'e' &&
                text[start + 4] == 'e' && text[start + 5] == 't');
    }
    return 0;
}

static size_t match_length(const uint8_t *text, size_t start, size_t end, size_t position) {
    size_t length = 0;
    if (position + 5 <= end && text[position] == 'b' && text[position + 1] == 'i' &&
        text[position + 2] == 'r' && text[position + 3] == 'd' &&
        text[position + 4] == 's') {
        length = 5;
    } else if (position + 6 <= end && text[position] == 'm' && text[position + 1] == 'a' &&
               text[position + 2] == 'r' && text[position + 3] == 'k' &&
               text[position + 4] == 'e' && text[position + 5] == 't') {
        length = 6;
    } else if (position + 6 <= end && text[position] == 's' && text[position + 1] == 't' &&
               text[position + 2] == 'r' && text[position + 3] == 'e' &&
               text[position + 4] == 'e' && text[position + 5] == 't') {
        length = 6;
    }
    if (length == 0) return 0;
    if (position > start && is_word(text[position - 1])) return 0;
    if (position + length < end && is_word(text[position + length])) return 0;
    return length;
}

static size_t append_token(const uint8_t *text, size_t start, size_t end,
                           const uint8_t *mask, size_t mask_length,
                           uint8_t *output, size_t output_length) {
    if (is_normalized_target(text, start, end)) {
        for (size_t i = 0; i < mask_length; ++i) output[output_length++] = mask[i];
        return output_length;
    }
    size_t position = start;
    while (position < end) {
        const size_t match = match_length(text, start, end, position);
        if (match != 0) {
            for (size_t i = 0; i < mask_length; ++i) output[output_length++] = mask[i];
            position += match;
        } else {
            if (text[position] != '\n') output[output_length++] = text[position];
            ++position;
        }
    }
    return output_length;
}

int64_t maskwords(const int64_t *values, size_t length,
                  uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (values[0] < 0 || values[0] > MAX_TEXT_BYTES) return -1;
    const size_t text_length = (size_t)values[0];
    const size_t mask_length_index = 1 + text_length;
    if (mask_length_index >= length) return -1;
    if (values[mask_length_index] < 0 || values[mask_length_index] > MAX_MASK_BYTES) return -1;
    const size_t mask_length = (size_t)values[mask_length_index];
    if (length != mask_length_index + 1 + mask_length) return -1;

    uint8_t text[MAX_TEXT_BYTES];
    uint8_t mask[MAX_MASK_BYTES];
    for (size_t i = 0; i < text_length; ++i) {
        const int64_t value = values[1 + i];
        if (value < 1 || value > 127) return -1;
        text[i] = (uint8_t)value;
    }
    for (size_t i = 0; i < mask_length; ++i) {
        const int64_t value = values[mask_length_index + 1 + i];
        if (value < 32 || value > 126 || value == '\\') return -1;
        mask[i] = (uint8_t)value;
    }

    uint8_t scratch[MAX_OUTPUT_BYTES];
    size_t written = 0;
    size_t start = 0;
    int have_token = 0;
    for (size_t i = 0; i < text_length; ++i) {
        if (text[i] == ' ') {
            if (have_token) scratch[written++] = ' ';
            written = append_token(text, start, i, mask, mask_length, scratch, written);
            have_token = 1;
            start = i + 1;
        }
    }
    if (start < text_length) {
        if (have_token) scratch[written++] = ' ';
        written = append_token(text, start, text_length, mask, mask_length, scratch, written);
    }
    if (written > MAX_OUTPUT_BYTES) return -1;
    if (output_capacity < written || (written != 0 && output == NULL)) return -2;
    for (size_t i = 0; i < written; ++i) output[i] = scratch[i];
    return (int64_t)written;
}
