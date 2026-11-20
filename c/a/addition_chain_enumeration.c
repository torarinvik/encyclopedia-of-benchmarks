#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_TARGET 31
#define MAX_OUTPUT_BYTES 24

typedef struct {
    int target;
    int limit;
    int chain[MAX_TARGET + 1];
    int64_t total_count;
    int64_t brauer_count;
} Search;

static void visit(Search *search, size_t length, bool prefix_is_brauer) {
    const int last = search->chain[length - 1];
    const int steps = (int)length - 1;
    if (last == search->target) {
        if (steps == search->limit) {
            ++search->total_count;
            if (prefix_is_brauer) ++search->brauer_count;
        }
        return;
    }
    const int remaining = search->limit - steps;
    if (remaining <= 0 || last * (1 << remaining) < search->target) return;

    bool generated[MAX_TARGET + 1] = {false};
    for (size_t left = 0; left < length; ++left) {
        for (size_t right = left; right < length; ++right) {
            const int candidate = search->chain[left] + search->chain[right];
            if (candidate <= last || candidate > search->target || generated[candidate]) continue;
            generated[candidate] = true;
            search->chain[length] = candidate;
            bool uses_last = false;
            for (size_t index = 0; index < length; ++index)
                if (last + search->chain[index] == candidate) uses_last = true;
            visit(search, length + 1, prefix_is_brauer && uses_last);
        }
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

static int popcount(int value) {
    int count = 0;
    while (value != 0) { count += value & 1; value >>= 1; }
    return count;
}

static int bit_length(int value) {
    int count = 0;
    while (value != 0) { ++count; value >>= 1; }
    return count;
}

static void minimum_counts(int target, int64_t result[3]) {
    if (target == 1) { result[0] = 0; result[1] = 1; result[2] = 0; return; }
    int lower = bit_length(target - 1);
    int upper = bit_length(target) - 1 + popcount(target) - 1;
    for (int limit = lower; limit <= upper; ++limit) {
        Search search = {.target = target, .limit = limit, .chain = {1}};
        visit(&search, 1, true);
        if (search.total_count != 0) {
            result[0] = limit;
            result[1] = search.brauer_count;
            result[2] = search.total_count - search.brauer_count;
            return;
        }
    }
}

int64_t addition_chain_enumeration(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length != 1 || input[0] < 1 || input[0] > MAX_TARGET) return -1;
    int64_t result[3] = {0, 0, 0};
    minimum_counts((int)input[0], result);
    if (output == NULL || capacity < MAX_OUTPUT_BYTES) return -2;
    for (size_t index = 0; index < 3; ++index) store_i64_le(output, index * 8, result[index]);
    return MAX_OUTPUT_BYTES;
}
