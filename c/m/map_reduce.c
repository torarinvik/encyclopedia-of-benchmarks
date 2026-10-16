/* Count bounded ASCII tokens in insertion order, matching the pinned Java routine. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 256
#define MAX_WORDS 128
#define TABLE_SIZE 512

static int is_space_byte(int64_t value)
{
    return value == 9 || value == 10 || value == 11 || value == 12 ||
           value == 13 || value == 32;
}

static size_t token_hash(const int64_t *input, size_t start, size_t length)
{
    size_t hash = 0;
    for (size_t offset = 0; offset < length; ++offset)
        hash = (hash * 31 + (size_t)input[start + offset]) % 1000003;
    return hash;
}

static int token_equal(const int64_t *input, size_t start, size_t token_length,
                       size_t other_start, size_t other_length)
{
    if (token_length != other_length) return 0;
    for (size_t offset = 0; offset < token_length; ++offset)
        if (input[start + offset] != input[other_start + offset]) return 0;
    return 1;
}

static size_t write_count(uint8_t *output, size_t position, size_t count)
{
    uint8_t digits[3];
    size_t digit_count = 0;
    do {
        digits[digit_count++] = (uint8_t)('0' + count % 10);
        count /= 10;
    } while (count != 0);
    while (digit_count != 0) output[position++] = digits[--digit_count];
    return position;
}

int64_t map_reduce(const int64_t *input, size_t length, uint8_t *output,
                   size_t output_capacity)
{
    if (length > MAX_INPUT || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = input[index];
        if (!is_space_byte(value) && (value < 32 || value > 126)) return -1;
    }

    size_t starts[MAX_WORDS], lengths[MAX_WORDS], counts[MAX_WORDS] = {0};
    size_t table[TABLE_SIZE] = {0};
    size_t unique_count = 0, begin = 0, end = length;
    while (begin < end && input[begin] <= 32) ++begin;
    while (end > begin && input[end - 1] <= 32) --end;

    if (begin == end) {
        starts[0] = 0; lengths[0] = 0; counts[0] = 1; unique_count = 1;
        table[0] = 1;
    } else {
        size_t cursor = begin;
        while (cursor < end) {
            while (cursor < end && is_space_byte(input[cursor])) ++cursor;
            if (cursor == end) break;
            const size_t start = cursor;
            while (cursor < end && !is_space_byte(input[cursor])) ++cursor;
            const size_t token_length = cursor - start;
            size_t slot = token_hash(input, start, token_length) % TABLE_SIZE;
            while (table[slot] != 0) {
                const size_t item = table[slot] - 1;
                if (token_equal(input, start, token_length, starts[item], lengths[item])) {
                    ++counts[item];
                    break;
                }
                slot = (slot + 1) % TABLE_SIZE;
            }
            if (table[slot] == 0) {
                starts[unique_count] = start;
                lengths[unique_count] = token_length;
                counts[unique_count] = 1;
                table[slot] = unique_count + 1;
                ++unique_count;
            }
        }
    }

    size_t required = 0;
    for (size_t item = 0; item < unique_count; ++item) {
        size_t digits = 1, value = counts[item];
        while (value >= 10) { value /= 10; ++digits; }
        required += lengths[item] + 2 + digits + (item != 0 ? 1 : 0);
    }
    if (output == NULL || output_capacity < required) return -2;

    size_t written = 0;
    for (size_t item = 0; item < unique_count; ++item) {
        if (item != 0) output[written++] = ',';
        for (size_t offset = 0; offset < lengths[item]; ++offset)
            output[written++] = (uint8_t)input[starts[item] + offset];
        output[written++] = ':';
        output[written++] = ' ';
        written = write_count(output, written, counts[item]);
    }
    return (int64_t)written;
}
