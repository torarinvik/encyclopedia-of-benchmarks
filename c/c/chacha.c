#include <stddef.h>
#include <stdint.h>

#define CHACHA_WORDS 16
#define CHACHA_BYTES 64
#define WORD_MASK UINT64_C(0xffffffff)

static uint64_t chacha_rotate_left(uint64_t value, unsigned int count)
{
    return ((value << count) | (value >> (32 - count))) & WORD_MASK;
}

static void chacha_quarter_round(uint64_t state[CHACHA_WORDS], int a, int b, int c, int d)
{
    state[a] = (state[a] + state[b]) & WORD_MASK;
    state[d] = chacha_rotate_left(state[d] ^ state[a], 16);
    state[c] = (state[c] + state[d]) & WORD_MASK;
    state[b] = chacha_rotate_left(state[b] ^ state[c], 12);
    state[a] = (state[a] + state[b]) & WORD_MASK;
    state[d] = chacha_rotate_left(state[d] ^ state[a], 8);
    state[c] = (state[c] + state[d]) & WORD_MASK;
    state[b] = chacha_rotate_left(state[b] ^ state[c], 7);
}

int64_t chacha(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length != CHACHA_WORDS) return -1;
    uint64_t initial[CHACHA_WORDS];
    for (size_t index = 0; index < CHACHA_WORDS; ++index) {
        if (input[index] < 0 || (uint64_t)input[index] > WORD_MASK) return -1;
        initial[index] = (uint64_t)input[index];
    }
    if (output == NULL || output_capacity < CHACHA_BYTES) return -2;

    uint64_t state[CHACHA_WORDS];
    for (size_t index = 0; index < CHACHA_WORDS; ++index) state[index] = initial[index];
    for (int round = 0; round < 10; ++round) {
        chacha_quarter_round(state, 0, 4, 8, 12);
        chacha_quarter_round(state, 1, 5, 9, 13);
        chacha_quarter_round(state, 2, 6, 10, 14);
        chacha_quarter_round(state, 3, 7, 11, 15);
        chacha_quarter_round(state, 0, 5, 10, 15);
        chacha_quarter_round(state, 1, 6, 11, 12);
        chacha_quarter_round(state, 2, 7, 8, 13);
        chacha_quarter_round(state, 3, 4, 9, 14);
    }
    for (size_t index = 0; index < CHACHA_WORDS; ++index) {
        const uint32_t word = (uint32_t)((state[index] + initial[index]) & WORD_MASK);
        output[4 * index] = (uint8_t)word;
        output[4 * index + 1] = (uint8_t)(word >> 8);
        output[4 * index + 2] = (uint8_t)(word >> 16);
        output[4 * index + 3] = (uint8_t)(word >> 24);
    }
    return CHACHA_BYTES;
}
