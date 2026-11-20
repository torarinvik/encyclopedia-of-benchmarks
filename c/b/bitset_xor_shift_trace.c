#include <stddef.h>
#include <stdint.h>

enum { MAX_BITS = 4096, MAX_WORDS = 64, MAX_OPERATIONS = 64 };

static uint32_t popcount64(uint64_t value) {
    uint32_t count = 0;
    while (value != 0) {
        value &= value - 1;
        ++count;
    }
    return count;
}

static void store_i32_le(uint8_t *output, size_t offset, int32_t value) {
    uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT32_C(255));
        bits >>= 8;
    }
}

int64_t bitset_xor_shift_trace(const int64_t *input, size_t length,
                              uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 3 || length > 131) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_BITS || q_value < 0 || q_value > MAX_OPERATIONS) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    const size_t word_count = (n + 63) / 64;
    const size_t shift_offset = 2 + word_count;
    if (length != shift_offset + q) return -1;

    uint64_t words[MAX_WORDS] = {0};
    for (size_t word = 0; word < word_count; ++word)
        words[word] = (uint64_t)input[2 + word];
    const size_t tail_bits = n % 64;
    const uint64_t tail_mask = tail_bits == 0 ? UINT64_MAX
                                               : (UINT64_C(1) << tail_bits) - 1;
    if ((words[word_count - 1] & ~tail_mask) != 0) return -1;
    for (size_t operation = 0; operation < q; ++operation) {
        const int64_t shift = input[shift_offset + operation];
        if (shift < -(n_value - 1) || shift > n_value - 1) return -1;
    }

    const size_t output_bytes = q * 4;
    if (output_bytes != 0 && (output == NULL || output_capacity < output_bytes)) return -2;
    int32_t counts[MAX_OPERATIONS] = {0};
    for (size_t operation = 0; operation < q; ++operation) {
        const int64_t shift = input[shift_offset + operation];
        if (shift == 0) {
            for (size_t word = 0; word < word_count; ++word) words[word] = 0;
        } else if (shift > 0) {
            const size_t distance = (size_t)shift;
            const size_t whole = distance / 64, part = distance % 64;
            for (size_t destination = 0; destination < word_count; ++destination) {
                const size_t source = destination + whole;
                uint64_t shifted = source < word_count ? words[source] >> part : 0;
                if (part != 0 && source + 1 < word_count)
                    shifted |= words[source + 1] << (64 - part);
                words[destination] ^= shifted;
            }
        } else {
            const size_t distance = (size_t)(-shift);
            const size_t whole = distance / 64, part = distance % 64;
            for (size_t destination = word_count; destination > 0; --destination) {
                const size_t target = destination - 1;
                const ptrdiff_t source = (ptrdiff_t)target - (ptrdiff_t)whole;
                uint64_t shifted = source >= 0 ? words[(size_t)source] << part : 0;
                if (part != 0 && source > 0)
                    shifted |= words[(size_t)source - 1] >> (64 - part);
                words[target] ^= shifted;
            }
        }
        words[word_count - 1] &= tail_mask;
        uint32_t count = 0;
        for (size_t word = 0; word < word_count; ++word) count += popcount64(words[word]);
        counts[operation] = (int32_t)count;
    }
    for (size_t operation = 0; operation < q; ++operation)
        store_i32_le(output, operation * 4, counts[operation]);
    return (int64_t)output_bytes;
}
