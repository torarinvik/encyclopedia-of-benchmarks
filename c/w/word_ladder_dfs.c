#include <stddef.h>
#include <stdint.h>

#define MAX_WORDS 8
#define MAX_PATH_WORDS (MAX_WORDS + 1)
#define MAX_INPUT_LENGTH (4 + MAX_WORDS)
#define MAX_OUTPUT_BYTES (8 * (MAX_PATH_WORDS + MAX_WORDS + 2))

static int64_t power_of_26(size_t exponent) {
    int64_t result = 1;
    for (size_t i = 0; i < exponent; ++i) result *= 26;
    return result;
}

static size_t find_active_word(const int64_t *words, const uint8_t *active,
                               size_t count, int64_t candidate) {
    for (size_t index = 0; index < count; ++index) {
        if (active[index] && words[index] == candidate) return index;
    }
    return count;
}

static int backtrack(int64_t current, int64_t end, size_t width,
                     const int64_t *words, size_t count, uint8_t *active,
                     int64_t *path, size_t *path_length) {
    if (current == end) return 1;
    for (size_t position = 0; position < width; ++position) {
        const int64_t factor = power_of_26(width - position - 1);
        const int64_t digit = (current / factor) % 26;
        for (int64_t replacement = 0; replacement < 26; ++replacement) {
            const int64_t candidate = current + (replacement - digit) * factor;
            const size_t index = find_active_word(words, active, count, candidate);
            if (index == count) continue;
            active[index] = 0;
            path[(*path_length)++] = candidate;
            if (backtrack(candidate, end, width, words, count, active, path, path_length)) return 1;
            --(*path_length);
            active[index] = 1;
        }
    }
    return 0;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t word_ladder_dfs(const int64_t *input, size_t length,
                        uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t width_value = input[0];
    const int64_t begin = input[1];
    const int64_t end = input[2];
    const int64_t count_value = input[3];
    if (width_value < 1 || width_value > 5 || count_value < 0 || count_value > MAX_WORDS ||
        length != 4 + (size_t)count_value) return -1;
    const size_t width = (size_t)width_value;
    const size_t count = (size_t)count_value;
    int64_t limit = power_of_26(width);
    if (begin < 0 || begin >= limit || end < 0 || end >= limit) return -1;
    const int64_t *words = input + 4;
    for (size_t index = 0; index < count; ++index) {
        if (words[index] < 0 || words[index] >= limit ||
            (index > 0 && words[index - 1] >= words[index])) return -1;
    }

    uint8_t active[MAX_WORDS] = {0};
    for (size_t index = 0; index < count; ++index) active[index] = 1;
    int64_t path[MAX_PATH_WORDS] = {0};
    size_t path_length = 0;
    path[0] = begin;
    path_length = 1;
    if (find_active_word(words, active, count, end) != count) {
        if (!backtrack(begin, end, width, words, count, active, path, &path_length))
            path_length = 0;
    } else {
        path_length = 0;
    }

    int64_t scratch[MAX_PATH_WORDS + MAX_WORDS + 2];
    size_t fields = 0;
    scratch[fields++] = (int64_t)path_length;
    for (size_t index = 0; index < path_length; ++index) scratch[fields++] = path[index];
    size_t remaining_count = 0;
    for (size_t index = 0; index < count; ++index) if (active[index]) ++remaining_count;
    scratch[fields++] = (int64_t)remaining_count;
    for (size_t index = 0; index < count; ++index) if (active[index]) scratch[fields++] = words[index];
    const size_t required = fields * 8;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t index = 0; index < fields; ++index) write_i64_le(output, index * 8, scratch[index]);
    return (int64_t)required;
}
