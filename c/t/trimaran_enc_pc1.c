/* Pukall Cipher 1 adaptation for the bounded Trimaran profile.
   Source author: Alexander Pukall (1991); source grants unrestricted use. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NUM_INPUT 2049

typedef struct {
    uint16_t words[16];
    uint16_t si;
    uint16_t x1a2;
} pc1_state;

static uint16_t code_step(pc1_state *state, uint16_t index) {
    uint16_t dx = (uint16_t)(state->x1a2 + index);
    uint16_t ax = state->words[index];
    uint16_t cx = 0x015a;
    const uint16_t bx = 0x4e35;
    uint16_t tmp = ax;
    ax = state->si;
    state->si = tmp;
    tmp = ax;
    ax = dx;
    dx = tmp;
    if (ax != 0) ax = (uint16_t)((uint32_t)ax * bx);
    tmp = ax;
    ax = cx;
    cx = tmp;
    if (ax != 0) {
        ax = (uint16_t)((uint32_t)ax * state->si);
        cx = (uint16_t)(ax + cx);
    }
    tmp = ax;
    ax = state->si;
    state->si = tmp;
    ax = (uint16_t)((uint32_t)ax * bx);
    dx = (uint16_t)(cx + dx);
    ax = (uint16_t)(ax + 1);
    state->x1a2 = dx;
    state->words[index] = ax;
    return (uint16_t)(ax ^ dx);
}

static uint16_t assemble(pc1_state *state, const uint8_t key[32]) {
    uint16_t inter = 0;
    state->words[0] = (uint16_t)(((uint16_t)key[0] << 8) | key[1]);
    inter = code_step(state, 0);
    for (uint16_t i = 1; i < 16; ++i) {
        uint16_t key_word = (uint16_t)(((uint16_t)key[2 * i] << 8) | key[2 * i + 1]);
        state->words[i] = (uint16_t)(state->words[i - 1] ^ key_word);
        inter = (uint16_t)(inter ^ code_step(state, i));
    }
    return inter;
}

static uint32_t lcg_next(uint32_t *seed) {
    *seed = (uint32_t)((uint64_t)(*seed) * 1664525u + 1013904223u);
    return (*seed >> 16) & 0x7fffu;
}

int64_t trimaran_enc_pc1(const int64_t *input, size_t length) {
    if (input == NULL || length != 1 || input[0] < 1 || input[0] > MAX_NUM_INPUT) return -1;
    static const char default_key[] = "abcdefghijklmnopqrstuvwxyz012345";
    uint8_t key[32];
    for (size_t i = 0; i < 32; ++i) key[i] = (uint8_t)default_key[i];
    pc1_state state = {{0}, 0, 0};
    uint32_t seed = 1;
    uint16_t last = 0;
    for (int64_t step = 0; step < input[0] - 1; ++step) {
        uint16_t plain = (uint16_t)lcg_next(&seed);
        uint16_t inter = assemble(&state, key);
        uint16_t high = (uint16_t)(inter >> 8);
        uint16_t low = (uint16_t)(inter & 255);
        uint16_t cipher = (uint16_t)(plain ^ (high ^ low));
        uint8_t feedback = (uint8_t)plain;
        for (size_t i = 0; i < 32; ++i) key[i] ^= feedback;
        last = cipher;
    }
    return last;
}
