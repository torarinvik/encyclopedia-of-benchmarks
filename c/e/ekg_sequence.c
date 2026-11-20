#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_CANDIDATE = 40320, MAX_PARSEABLE_LENGTH = 2 };

static int64_t gcd_i64(int64_t left, int64_t right) {
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t ekg_sequence(const int64_t *input, size_t length,
                     uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t requested = input[0];
    if (length != 1 || requested < 1 || requested > MAX_N) return -1;

    int64_t terms[MAX_N] = {0};
    uint8_t used[MAX_CANDIDATE + 1] = {0};
    terms[0] = 1;
    used[1] = 1;
    size_t term_count = 1;
    if (requested >= 2) {
        terms[1] = 2;
        used[2] = 1;
        term_count = 2;
    }

    while (term_count < (size_t)requested) {
        const int64_t position = (int64_t)term_count + 1;
        const int64_t previous = terms[term_count - 1];
        const int64_t search_bound = previous * position;
        int64_t candidate = 1;
        while (candidate <= search_bound) {
            if (used[(size_t)candidate] == 0
                && gcd_i64(previous, candidate) > 1) break;
            ++candidate;
        }
        if (candidate > search_bound) return -1;
        terms[term_count++] = candidate;
        used[(size_t)candidate] = 1;
    }

    const size_t output_bytes = (size_t)requested * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < term_count; ++index)
        store_i64_le(output, index * 8, terms[index]);
    return (int64_t)output_bytes;
}
