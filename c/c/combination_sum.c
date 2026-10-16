#include <stddef.h>
#include <stdint.h>

#define MAX_CANDIDATES 8
#define MAX_TARGET 20
#define MAX_PACKED_WORDS 4096

typedef struct {
    const int64_t *candidates;
    size_t count;
    int64_t path[MAX_TARGET];
    int64_t packed[MAX_PACKED_WORDS];
    size_t used;
} Search;

static void enumerate(Search *search, size_t start, int64_t remaining, size_t depth) {
    if (remaining == 0) {
        search->packed[search->used++] = (int64_t)depth;
        for (size_t i = 0; i < depth; ++i) search->packed[search->used++] = search->path[i];
        ++search->packed[0];
        return;
    }
    for (size_t i = start; i < search->count; ++i) {
        const int64_t candidate = search->candidates[i];
        if (candidate > remaining) break;
        search->path[depth] = candidate;
        enumerate(search, i, remaining - candidate, depth + 1);
    }
}

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t combination_sum(const int64_t *input, size_t length,
                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3) return -1;
    const int64_t count_value = input[0], target = input[1];
    if (count_value < 1 || count_value > MAX_CANDIDATES || target < 0 || target > MAX_TARGET)
        return -1;
    const size_t count = (size_t)count_value;
    if (length != count + 2) return -1;
    for (size_t i = 0; i < count; ++i) {
        const int64_t candidate = input[i + 2];
        if (candidate < 1 || candidate > 24 || (i > 0 && input[i + 1] >= candidate)) return -1;
    }

    Search search = { .candidates = input + 2, .count = count, .used = 1 };
    search.packed[0] = 0;
    enumerate(&search, 0, target, 0);
    const size_t required = search.used * 8;
    if (output == NULL || capacity < required) return -2;
    for (size_t i = 0; i < search.used; ++i) put_i64(output, i * 8, search.packed[i]);
    return (int64_t)required;
}
