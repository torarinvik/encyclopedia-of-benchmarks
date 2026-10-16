/* Sort bounded decimal strings by the pinned length/lexicographic comparator. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 64
#define MAX_TOKEN_LENGTH 32
#define MAX_INPUT_LENGTH 2113

typedef struct {
    size_t start;
    size_t length;
    size_t normalized_start;
    size_t normalized_length;
} token_ref;

static int token_less(const int64_t *values, const token_ref *left,
                      const token_ref *right)
{
    if (left->normalized_length != right->normalized_length)
        return left->normalized_length < right->normalized_length;
    for (size_t i = 0; i < left->normalized_length; ++i) {
        const int64_t a = values[left->normalized_start + i];
        const int64_t b = values[right->normalized_start + i];
        if (a != b) return a < b;
    }
    return 0;
}

int64_t numeric_string_sort(const int64_t *values, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length == 0 || length > MAX_INPUT_LENGTH + 1) return -1;
    if (values[0] < 0 || values[0] > MAX_ITEMS) return -1;
    const size_t count = (size_t)values[0];
    token_ref tokens[MAX_ITEMS];
    size_t order[MAX_ITEMS];
    size_t cursor = 1;
    size_t output_length = count == 0 ? 0 : count - 1;

    for (size_t i = 0; i < count; ++i) {
        if (cursor >= length) return -1;
        const int64_t raw_length = values[cursor++];
        if (raw_length < 1 || raw_length > MAX_TOKEN_LENGTH ||
            (size_t)raw_length > length - cursor) return -1;
        const size_t token_length = (size_t)raw_length;
        const size_t start = cursor;
        for (size_t j = 0; j < token_length; ++j)
            if (values[start + j] < '0' || values[start + j] > '9') return -1;
        size_t zeros = 0;
        while (zeros < token_length && values[start + zeros] == '0') ++zeros;
        tokens[i] = (token_ref){start, token_length, start + zeros, token_length - zeros};
        for (size_t j = 0; j < i; ++j) {
            const token_ref *previous = &tokens[j];
            if (previous->normalized_length != tokens[i].normalized_length) continue;
            size_t k = 0;
            while (k < tokens[i].normalized_length &&
                   values[previous->normalized_start + k] == values[tokens[i].normalized_start + k]) ++k;
            if (k == tokens[i].normalized_length && previous->length != token_length) return -1;
            if (k == tokens[i].normalized_length && previous->length == token_length) {
                size_t raw = 0;
                while (raw < token_length && values[previous->start + raw] == values[start + raw]) ++raw;
                if (raw != token_length) return -1;
            }
        }
        output_length += token_length;
        cursor += token_length;
        order[i] = i;
    }
    if (cursor != length || output_length > MAX_ITEMS * MAX_TOKEN_LENGTH + MAX_ITEMS - 1) return -1;

    for (size_t i = 1; i < count; ++i) {
        const size_t key = order[i];
        size_t position = i;
        while (position > 0 && token_less(values, &tokens[key], &tokens[order[position - 1]])) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = key;
    }
    if (output == NULL && output_length != 0) return -2;
    if (output_capacity < output_length) return -2;
    size_t written = 0;
    for (size_t i = 0; i < count; ++i) {
        if (i != 0) output[written++] = (uint8_t)' ';
        const token_ref token = tokens[order[i]];
        for (size_t j = 0; j < token.length; ++j)
            output[written++] = (uint8_t)values[token.start + j];
    }
    return (int64_t)output_length;
}
