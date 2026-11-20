#include <stddef.h>
#include <stdint.h>

#define MIN_LISTS 2
#define MAX_LISTS 8
#define MAX_LIST_LENGTH 32
#define MAX_INPUT_LENGTH (MAX_LISTS * (MAX_LIST_LENGTH + 1) + 2)
#define BYTES_PER_VALUE 4

static void store_i32_le(uint8_t *output, size_t position, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < BYTES_PER_VALUE; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t inverted_list_svs_binary_search(const int64_t *input, size_t length,
    uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < MIN_LISTS + 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0];
    if (count_value < MIN_LISTS || count_value > MAX_LISTS) return -1;
    const size_t count = (size_t)count_value;
    size_t starts[MAX_LISTS], sizes[MAX_LISTS], order[MAX_LISTS];
    size_t position = 1;
    for (size_t list = 0; list < count; ++list) {
        if (position >= length || input[position] < 0 || input[position] > MAX_LIST_LENGTH) return -1;
        const size_t size = (size_t)input[position++];
        if (size > length - position) return -1;
        starts[list] = position;
        sizes[list] = size;
        order[list] = list;
        for (size_t i = 0; i < size; ++i) {
            const int64_t value = input[position + i];
            if (value < INT32_MIN || value > INT32_MAX) return -1;
            if (i > 0 && input[position + i - 1] >= value) return -1;
        }
        position += size;
    }
    if (position != length) return -1;

    for (size_t i = 1; i < count; ++i) {
        const size_t key = order[i];
        size_t j = i;
        while (j > 0 && sizes[order[j - 1]] > sizes[key]) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = key;
    }
    size_t maximum_result = sizes[order[0]];
    if (output_capacity < maximum_result * BYTES_PER_VALUE ||
        (maximum_result != 0 && output == NULL)) return -2;

    int32_t candidates[MAX_LIST_LENGTH];
    size_t candidate_count = sizes[order[0]];
    for (size_t i = 0; i < candidate_count; ++i)
        candidates[i] = (int32_t)input[starts[order[0]] + i];

    for (size_t rank = 1; rank < count && candidate_count != 0; ++rank) {
        const size_t list = order[rank];
        const size_t start = starts[list], size = sizes[list];
        size_t cursor = 0, kept = 0;
        for (size_t i = 0; i < candidate_count; ++i) {
            const int32_t candidate = candidates[i];
            size_t low = cursor, high = size;
            while (low < high) {
                const size_t middle = low + (high - low) / 2;
                if (input[start + middle] < candidate) low = middle + 1;
                else high = middle;
            }
            if (low < size && input[start + low] == candidate) {
                candidates[kept++] = candidate;
                cursor = low + 1;
            } else {
                cursor = low;
            }
        }
        candidate_count = kept;
    }
    for (size_t i = 0; i < candidate_count; ++i)
        store_i32_le(output, i * BYTES_PER_VALUE, candidates[i]);
    return (int64_t)candidate_count;
}
