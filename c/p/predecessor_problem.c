#include <stddef.h>
#include <stdint.h>

#define MAX_N 4096
#define MAX_WORDS ((MAX_N + 63) / 64)
#define MAX_QUERIES 512
#define MAX_INPUT_LENGTH (2 + MAX_WORDS + 2 * MAX_QUERIES)
#define MAX_OUTPUT_BYTES (MAX_QUERIES * 8)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static int64_t find_next(const uint64_t *words, size_t word_count, size_t n, size_t key) {
    const size_t first_word = key / 64;
    for (size_t word = first_word; word < word_count; ++word) {
        const size_t first_bit = word == first_word ? key % 64 : 0;
        uint64_t candidates = words[word];
        if (first_bit != 0) candidates &= UINT64_MAX << first_bit;
        if (candidates == 0) continue;
        const size_t end_bit = (word + 1) * 64 < n ? 64 : n - word * 64;
        for (size_t bit = first_bit; bit < end_bit; ++bit)
            if (((candidates >> bit) & 1U) != 0) return (int64_t)(word * 64 + bit);
    }
    return -1;
}

static int64_t find_previous(const uint64_t *words, size_t n, size_t key) {
    const size_t first_word = key / 64;
    for (size_t word = first_word + 1; word > 0; --word) {
        const size_t index = word - 1;
        uint64_t candidates = words[index];
        const size_t valid_bits = (index + 1) * 64 > n ? n - index * 64 : 64;
        const size_t requested_end = index == first_word ? key % 64 + 1 : valid_bits;
        const size_t end_bit = requested_end < valid_bits ? requested_end : valid_bits;
        if (end_bit == 0) continue;
        const uint64_t mask = end_bit == 64 ? UINT64_MAX : (UINT64_C(1) << end_bit) - 1;
        candidates &= mask;
        if (candidates == 0) continue;
        for (size_t bit = end_bit; bit > 0; --bit)
            if (((candidates >> (bit - 1)) & 1U) != 0)
                return (int64_t)(index * 64 + bit - 1);
    }
    return -1;
}

int64_t predecessor_problem(const int64_t *input, size_t length,
                            uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0], query_value = input[1];
    if (n_value < 1 || n_value > MAX_N || query_value < 0 || query_value > MAX_QUERIES) return -1;
    const size_t n = (size_t)n_value, queries = (size_t)query_value;
    const size_t word_count = (n + 63) / 64;
    const size_t operation_offset = 2 + word_count;
    if (length != operation_offset + 2 * queries) return -1;
    uint64_t words[MAX_WORDS] = {0};
    for (size_t word = 0; word < word_count; ++word) words[word] = (uint64_t)input[2 + word];
    const size_t tail_bits = n % 64;
    if (tail_bits != 0 && (words[word_count - 1] >> tail_bits) != 0) return -1;
    for (size_t query = 0; query < queries; ++query) {
        const int64_t operation = input[operation_offset + 2 * query];
        const int64_t key = input[operation_offset + 2 * query + 1];
        if (operation < 0 || operation > 4 || key < 0 || key >= n_value) return -1;
    }
    int64_t answers[MAX_QUERIES] = {0};
    size_t answer_count = 0;
    for (size_t query = 0; query < queries; ++query) {
        const int64_t operation = input[operation_offset + 2 * query];
        const size_t key = (size_t)input[operation_offset + 2 * query + 1];
        const size_t word = key / 64;
        const uint64_t mask = UINT64_C(1) << (key % 64);
        if (operation == 0) words[word] |= mask;
        else if (operation == 1) words[word] &= ~mask;
        else if (operation == 2) answers[answer_count++] = (words[word] & mask) != 0;
        else if (operation == 3) answers[answer_count++] = find_next(words, word_count, n, key);
        else answers[answer_count++] = find_previous(words, n, key);
    }
    const size_t output_bytes = answer_count * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (size_t index = 0; index < answer_count; ++index) store_i64_le(staged, index * 8, answers[index]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
