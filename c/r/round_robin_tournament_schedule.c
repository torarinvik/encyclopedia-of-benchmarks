#include <stddef.h>
#include <stdint.h>

enum { MAX_TEAMS = 8, MAX_PARSEABLE_INPUT = 2, MAX_CELLS = 64 };

int64_t round_robin_tournament_schedule(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_INPUT) return -1;
    if (length != 1) return -1;
    const int64_t n_word = input[0];
    if (n_word < 2 || n_word > MAX_TEAMS) return -1;

    const size_t n = (size_t)n_word;
    const size_t padded = n + (n & 1U);
    const size_t ring_size = padded - 1;
    const size_t rounds = ring_size;
    const size_t fixed = padded - 1;
    uint8_t table[MAX_CELLS];
    for (size_t i = 0; i < MAX_CELLS; ++i) table[i] = UINT8_MAX;

    for (size_t round = 0; round < rounds; ++round) {
        if (fixed < n) {
            table[fixed * rounds + round] = (uint8_t)round;
            table[round * rounds + round] = (uint8_t)fixed;
        }
        for (size_t offset = 1; offset < padded / 2; ++offset) {
            const size_t left = (round + offset) % ring_size;
            const size_t right = (round + ring_size - offset) % ring_size;
            if (left < n && right < n) {
                table[left * rounds + round] = (uint8_t)right;
                table[right * rounds + round] = (uint8_t)left;
            }
        }
    }

    const size_t required = 2 + n * rounds;
    if (output == NULL || capacity < required) return -2;
    output[0] = (uint8_t)n;
    output[1] = (uint8_t)rounds;
    for (size_t i = 0; i < n * rounds; ++i) output[2 + i] = table[i];
    return (int64_t)required;
}
