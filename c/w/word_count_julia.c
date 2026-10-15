/* Count Julia-regex words after ASCII lowercasing. */
#include <stddef.h>
#include <stdint.h>

#define MAX_WORD_COUNT_JULIA_LENGTH 1000

typedef struct {
    size_t start;
    size_t length;
    size_t count;
} word_entry;

static uint8_t lower_byte(const int64_t *input, size_t index)
{
    uint8_t byte = (uint8_t)input[index];
    return byte >= 'A' && byte <= 'Z' ? (uint8_t)(byte + ('a' - 'A')) : byte;
}

static int is_word_byte(uint8_t byte)
{
    return (byte >= 'a' && byte <= 'z') || (byte >= '0' && byte <= '9') || byte == '_';
}

static int compare_word(const int64_t *input, size_t start, size_t length,
                        const word_entry *entry)
{
    size_t shared = length < entry->length ? length : entry->length;
    for (size_t i = 0; i < shared; ++i) {
        uint8_t left = lower_byte(input, start + i);
        uint8_t right = lower_byte(input, entry->start + i);
        if (left != right) return left < right ? -1 : 1;
    }
    return length < entry->length ? -1 : length > entry->length ? 1 : 0;
}

static size_t write_count(uint8_t *output, size_t position, size_t count)
{
    uint8_t digits[4];
    size_t digit_count = 0;
    do {
        digits[digit_count++] = (uint8_t)('0' + count % 10);
        count /= 10;
    } while (count != 0);
    output[position++] = '=';
    while (digit_count != 0) output[position++] = digits[--digit_count];
    output[position++] = '\n';
    return position;
}

int64_t word_count_julia(const int64_t *input, size_t length,
                         uint8_t *output, size_t output_capacity)
{
    if (length > MAX_WORD_COUNT_JULIA_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t i = 0; i < length; ++i)
        if (input[i] < 0 || input[i] > 127) return -1;

    word_entry entries[MAX_WORD_COUNT_JULIA_LENGTH];
    size_t unique_count = 0;
    size_t index = 0;
    while (index < length) {
        if (!is_word_byte(lower_byte(input, index))) { ++index; continue; }
        size_t start = index;
        while (index < length && is_word_byte(lower_byte(input, index))) ++index;
        size_t token_length = index - start;
        if (index + 1 < length && input[index] == '\'' && is_word_byte(lower_byte(input, index + 1))) {
            token_length += 2;
            index += 2;
        }

        size_t position = 0;
        while (position < unique_count && compare_word(input, start, token_length, &entries[position]) > 0)
            ++position;
        if (position < unique_count && compare_word(input, start, token_length, &entries[position]) == 0) {
            ++entries[position].count;
        } else {
            for (size_t move = unique_count; move > position; --move) entries[move] = entries[move - 1];
            entries[position] = (word_entry){start, token_length, 1};
            ++unique_count;
        }
    }

    size_t required = 0;
    for (size_t item = 0; item < unique_count; ++item) {
        size_t digits = 1;
        for (size_t value = entries[item].count; value >= 10; value /= 10) ++digits;
        required += entries[item].length + 1 + digits + 1;
    }
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;

    size_t written = 0;
    for (size_t item = 0; item < unique_count; ++item) {
        for (size_t offset = 0; offset < entries[item].length; ++offset)
            output[written++] = lower_byte(input, entries[item].start + offset);
        written = write_count(output, written, entries[item].count);
    }
    return (int64_t)written;
}
