#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 16
#define MAX_STRING_LENGTH 64

static int compare_strings(const int64_t *input, size_t start_a, size_t len_a,
                           size_t start_b, size_t len_b) {
    size_t limit = len_a < len_b ? len_a : len_b;
    for (size_t i = 0; i < limit; ++i) {
        if (input[start_a + i] < input[start_b + i]) return -1;
        if (input[start_a + i] > input[start_b + i]) return 1;
    }
    return len_a < len_b ? -1 : len_a > len_b ? 1 : 0;
}

int64_t longest_common_prefix(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 1 + MAX_COUNT * (MAX_STRING_LENGTH + 1)) return -1;
    if (input[0] < 0 || input[0] > MAX_COUNT) return -1;
    size_t count = (size_t)input[0], starts[MAX_COUNT], sizes[MAX_COUNT], position = 1;
    for (size_t i = 0; i < count; ++i) {
        if (position >= length || input[position] < 0 || input[position] > MAX_STRING_LENGTH) return -1;
        sizes[i] = (size_t)input[position++];
        if (sizes[i] > length - position) return -1;
        starts[i] = position;
        for (size_t j = 0; j < sizes[i]; ++j) if (input[position + j] < 0 || input[position + j] > 127) return -1;
        position += sizes[i];
    }
    if (position != length) return -1;
    if (count == 0) return 0;
    size_t order[MAX_COUNT];
    for (size_t i = 0; i < count; ++i) order[i] = i;
    for (size_t i = 1; i < count; ++i) {
        size_t value = order[i], j = i;
        while (j > 0 && compare_strings(input, starts[order[j - 1]], sizes[order[j - 1]], starts[value], sizes[value]) > 0) {
            order[j] = order[j - 1]; --j;
        }
        order[j] = value;
    }
    size_t first = order[0], last = order[count - 1];
    size_t limit = sizes[first] < sizes[last] ? sizes[first] : sizes[last], prefix = 0;
    while (prefix < limit && input[starts[first] + prefix] == input[starts[last] + prefix]) ++prefix;
    if (capacity < prefix || (prefix != 0 && output == NULL)) return -2;
    for (size_t i = 0; i < prefix; ++i) output[i] = (uint8_t)input[starts[first] + i];
    return (int64_t)prefix;
}
