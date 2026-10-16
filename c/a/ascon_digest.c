/* Portable scalar port of TheAlgorithms/C-Sharp AsconDigest. */
#include <stddef.h>
#include <stdint.h>

#define MAX_MESSAGE_BYTES 4096

static uint64_t rotate_right(uint64_t value, unsigned count) {
    return (value >> count) | (value << (64u - count));
}

static void permute(uint64_t state[5], unsigned rounds) {
    static const uint8_t constants[12] = {
        0xf0, 0xe1, 0xd2, 0xc3, 0xb4, 0xa5, 0x96, 0x87, 0x78, 0x69, 0x5a, 0x4b
    };
    unsigned first = rounds == 12 ? 0 : 4;
    for (unsigned round = first; round < 12; ++round) {
        uint64_t x0 = state[0], x1 = state[1], x2 = state[2], x3 = state[3], x4 = state[4];
        uint64_t c = constants[round];
        uint64_t t0 = x0 ^ x1 ^ x2 ^ x3 ^ c ^ (x1 & (x0 ^ x2 ^ x4 ^ c));
        uint64_t t1 = x0 ^ x2 ^ x3 ^ x4 ^ c ^ ((x1 ^ x2 ^ c) & (x1 ^ x3));
        uint64_t t2 = x1 ^ x2 ^ x4 ^ c ^ (x3 & x4);
        uint64_t t3 = x0 ^ x1 ^ x2 ^ c ^ (~x0 & (x3 ^ x4));
        uint64_t t4 = x1 ^ x3 ^ x4 ^ ((x0 ^ x4) & x1);
        state[0] = t0 ^ rotate_right(t0, 19) ^ rotate_right(t0, 28);
        state[1] = t1 ^ rotate_right(t1, 39) ^ rotate_right(t1, 61);
        state[2] = ~(t2 ^ rotate_right(t2, 1) ^ rotate_right(t2, 6));
        state[3] = t3 ^ rotate_right(t3, 10) ^ rotate_right(t3, 17);
        state[4] = t4 ^ rotate_right(t4, 7) ^ rotate_right(t4, 41);
    }
}

static void write_u64_be(uint8_t *output, size_t offset, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(value >> (56u - byte * 8u));
}

int64_t ascon_digest(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2) return -1;
    int64_t variant = input[0], message_length_value = input[1];
    if ((variant != 0 && variant != 1) || message_length_value < 0 ||
        message_length_value > MAX_MESSAGE_BYTES || length != (size_t)message_length_value + 2)
        return -1;
    size_t message_length = (size_t)message_length_value;
    for (size_t index = 0; index < message_length; ++index)
        if (input[index + 2] < 0 || input[index + 2] > 255) return -1;

    uint64_t state[5];
    if (variant == 0) {
        state[0] = UINT64_C(0xee9398aadb67f03d); state[1] = UINT64_C(0x8bb21831c60f1002);
        state[2] = UINT64_C(0xb48a92db98d5da62); state[3] = UINT64_C(0x43189921b8f8e3e8);
        state[4] = UINT64_C(0x348fa5c9d525e140);
    } else {
        state[0] = UINT64_C(0x01470194fc6528a6); state[1] = UINT64_C(0x738ec38ac0adffa7);
        state[2] = UINT64_C(0x2ec8e3296c76384c); state[3] = UINT64_C(0xd6f6a54d7f52377d);
        state[4] = UINT64_C(0xa13c42a223be8d87);
    }
    unsigned rounds = variant == 0 ? 12 : 8;
    size_t complete_length = message_length - message_length % 8;
    for (size_t offset = 0; offset < complete_length; offset += 8) {
        uint64_t word = 0;
        for (unsigned byte = 0; byte < 8; ++byte)
            word = (word << 8) | (uint64_t)input[offset + byte + 2];
        state[0] ^= word;
        permute(state, rounds);
    }
    size_t tail_length = message_length - complete_length;
    uint64_t final_word = UINT64_C(0x80) << (56u - (unsigned)tail_length * 8u);
    for (size_t byte = 0; byte < tail_length; ++byte)
        final_word |= (uint64_t)input[complete_length + byte + 2] << (56u - (unsigned)byte * 8u);
    state[0] ^= final_word;
    permute(state, 12);

    if (output == NULL || capacity < 32) return -2;
    for (unsigned block = 0; block < 4; ++block) {
        write_u64_be(output, (size_t)block * 8, state[0]);
        if (block != 3) permute(state, rounds);
    }
    return 32;
}
