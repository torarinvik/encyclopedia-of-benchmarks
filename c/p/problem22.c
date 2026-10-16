#include <stddef.h>
#include <stdint.h>

#define MAX_NAMES 6000
#define MAX_NAME_LENGTH 19
#define MAX_INPUT_LENGTH 100001

static int problem22_compare_names(const int64_t *input,
                                  const size_t *offsets,
                                  const size_t *name_lengths,
                                  size_t first, size_t second)
{
    const size_t first_length = name_lengths[first];
    const size_t second_length = name_lengths[second];
    const size_t shared_length = first_length < second_length ? first_length : second_length;
    for (size_t index = 0; index < shared_length; ++index) {
        const int64_t first_letter = input[offsets[first] + index];
        const int64_t second_letter = input[offsets[second] + index];
        if (first_letter < second_letter) return -1;
        if (first_letter > second_letter) return 1;
    }
    if (first_length < second_length) return -1;
    if (first_length > second_length) return 1;
    return 0;
}

int64_t problem22(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > MAX_NAMES) return -1;
    const size_t count = (size_t)raw_count;
    size_t offsets[MAX_NAMES];
    size_t name_lengths[MAX_NAMES];
    size_t order[MAX_NAMES];
    size_t cursor = 1;
    for (size_t name = 0; name < count; ++name) {
        if (cursor >= length) return -1;
        const int64_t raw_name_length = input[cursor++];
        if (raw_name_length < 1 || raw_name_length > MAX_NAME_LENGTH) return -1;
        const size_t name_length = (size_t)raw_name_length;
        if (name_length > length - cursor) return -1;
        offsets[name] = cursor;
        name_lengths[name] = name_length;
        for (size_t letter = 0; letter < name_length; ++letter) {
            if (input[cursor + letter] < 1 || input[cursor + letter] > 26) return -1;
        }
        cursor += name_length;
        order[name] = name;
    }
    if (cursor != length) return -1;

    static const size_t gaps[] = {701, 301, 132, 57, 23, 10, 4, 1};
    for (size_t gap_index = 0; gap_index < sizeof(gaps) / sizeof(gaps[0]); ++gap_index) {
        const size_t gap = gaps[gap_index];
        if (gap >= count) continue;
        for (size_t index = gap; index < count; ++index) {
            const size_t key = order[index];
            size_t position = index;
            while (position >= gap &&
                   problem22_compare_names(input, offsets, name_lengths,
                                           order[position - gap], key) > 0) {
                order[position] = order[position - gap];
                position -= gap;
            }
            order[position] = key;
        }
    }

    int64_t total = 0;
    for (size_t position = 0; position < count; ++position) {
        const size_t name = order[position];
        int64_t score = 0;
        for (size_t letter = 0; letter < name_lengths[name]; ++letter) {
            score += input[offsets[name] + letter];
        }
        total += (int64_t)(position + 1) * score;
    }
    return total;
}
