#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT_LENGTH = 64, MAX_INPUT_LENGTH = 65 };

static bool pair_less(size_t left, size_t right, const int64_t *rank,
                      size_t length, size_t step)
{
    if (rank[left] != rank[right]) return rank[left] < rank[right];
    const int64_t left_second = left + step < length ? rank[left + step] : -1;
    const int64_t right_second = right + step < length ? rank[right + step] : -1;
    return left_second < right_second;
}

int64_t suffix_array(const int64_t *values, size_t length,
                     uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_TEXT_LENGTH) return -1;
    const size_t count = (size_t)count_value;
    if (length != 1 + count) return -1;
    for (size_t i = 0; i < count; ++i)
        if (values[1 + i] < 0 || values[1 + i] > 127) return -1;

    const size_t output_bytes = count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    if (count == 0) return 0;

    size_t suffixes[MAX_TEXT_LENGTH];
    int64_t rank[MAX_TEXT_LENGTH], next_rank[MAX_TEXT_LENGTH];
    for (size_t i = 0; i < count; ++i) {
        suffixes[i] = i;
        rank[i] = values[1 + i];
    }

    for (size_t step = 1; step < count; step *= 2) {
        for (size_t i = 1; i < count; ++i) {
            const size_t key = suffixes[i];
            size_t position = i;
            while (position > 0 && pair_less(key, suffixes[position - 1], rank, count, step)) {
                suffixes[position] = suffixes[position - 1];
                --position;
            }
            suffixes[position] = key;
        }
        next_rank[suffixes[0]] = 0;
        for (size_t i = 1; i < count; ++i) {
            const size_t previous = suffixes[i - 1];
            const size_t current = suffixes[i];
            const int64_t previous_second = previous + step < count ? rank[previous + step] : -1;
            const int64_t current_second = current + step < count ? rank[current + step] : -1;
            next_rank[current] = next_rank[previous] +
                ((rank[previous] == rank[current] && previous_second == current_second) ? 0 : 1);
        }
        for (size_t i = 0; i < count; ++i) rank[i] = next_rank[i];
        if (rank[suffixes[count - 1]] == (int64_t)count - 1) break;
    }

    for (size_t i = 0; i < count; ++i) {
        const uint64_t bits = (uint64_t)suffixes[i];
        for (size_t byte = 0; byte < 8; ++byte)
            output[i * 8 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)output_bytes;
}
