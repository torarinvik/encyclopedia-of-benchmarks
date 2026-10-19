#include <stddef.h>
#include <stdint.h>

static uint16_t idea_mul(uint16_t left, uint16_t right) {
    uint64_t a = left == 0 ? 65536u : left;
    uint64_t b = right == 0 ? 65536u : right;
    uint64_t residue = (a * b) % 65537u;
    return residue == 65536u ? 0 : (uint16_t)residue;
}

static uint16_t idea_inverse(uint16_t value) {
    int64_t a = value == 0 ? 65536 : value;
    int64_t old_r = 65537, r = a, old_s = 0, s = 1;
    while (r != 0) {
        int64_t quotient = old_r / r;
        int64_t next_r = old_r - quotient * r;
        int64_t next_s = old_s - quotient * s;
        old_r = r; r = next_r; old_s = s; s = next_s;
    }
    old_s %= 65537;
    if (old_s < 0) old_s += 65537;
    return old_s == 65536 ? 0 : (uint16_t)old_s;
}

static void expand_key(const uint16_t key[8], uint16_t subkeys[52]) {
    uint16_t state[8];
    for (size_t i = 0; i < 8; ++i) state[i] = key[i];
    for (size_t offset = 0; offset < 52; offset += 8) {
        size_t amount = 52 - offset < 8 ? 52 - offset : 8;
        for (size_t i = 0; i < amount; ++i) subkeys[offset + i] = state[i];
        uint16_t rotated[8];
        for (size_t i = 0; i < 8; ++i)
            rotated[i] = (uint16_t)((state[(i + 1) & 7] << 9) | (state[(i + 2) & 7] >> 7));
        for (size_t i = 0; i < 8; ++i) state[i] = rotated[i];
    }
}

static void encrypt_block(const uint16_t key[52], const uint16_t plain[4], uint16_t cipher[4]) {
    uint16_t x1 = plain[0], x2 = plain[1], x3 = plain[2], x4 = plain[3];
    for (size_t round = 0; round < 8; ++round) {
        const uint16_t *k = key + round * 6;
        uint16_t a = idea_mul(x1, k[0]);
        uint16_t b = (uint16_t)(x2 + k[1]);
        uint16_t c = (uint16_t)(x3 + k[2]);
        uint16_t d = idea_mul(x4, k[3]);
        uint16_t p = idea_mul((uint16_t)(a ^ c), k[4]);
        uint16_t q = idea_mul((uint16_t)((b ^ d) + p), k[5]);
        uint16_t r = (uint16_t)(p + q);
        x1 = (uint16_t)(a ^ q);
        x2 = (uint16_t)(c ^ q);
        x3 = (uint16_t)(b ^ r);
        x4 = (uint16_t)(d ^ r);
    }
    cipher[0] = idea_mul(x1, key[48]);
    cipher[1] = (uint16_t)(x3 + key[49]);
    cipher[2] = (uint16_t)(x2 + key[50]);
    cipher[3] = idea_mul(x4, key[51]);
}

static void decrypt_block(const uint16_t key[52], const uint16_t cipher[4], uint16_t plain[4]) {
    uint16_t x1 = idea_mul(cipher[0], idea_inverse(key[48]));
    uint16_t x2 = (uint16_t)(cipher[2] - key[50]);
    uint16_t x3 = (uint16_t)(cipher[1] - key[49]);
    uint16_t x4 = idea_mul(cipher[3], idea_inverse(key[51]));
    for (size_t step = 8; step > 0; --step) {
        const uint16_t *k = key + (step - 1) * 6;
        uint16_t a = (uint16_t)(x1 ^ x2);
        uint16_t b = (uint16_t)(x3 ^ x4);
        uint16_t p = idea_mul(a, k[4]);
        uint16_t q = idea_mul((uint16_t)(b + p), k[5]);
        uint16_t r = (uint16_t)(p + q);
        uint16_t old_a = (uint16_t)(x1 ^ q);
        uint16_t old_c = (uint16_t)(x2 ^ q);
        uint16_t old_b = (uint16_t)(x3 ^ r);
        uint16_t old_d = (uint16_t)(x4 ^ r);
        x1 = idea_mul(old_a, idea_inverse(k[0]));
        x2 = (uint16_t)(old_b - k[1]);
        x3 = (uint16_t)(old_c - k[2]);
        x4 = idea_mul(old_d, idea_inverse(k[3]));
    }
    plain[0] = x1; plain[1] = x2; plain[2] = x3; plain[3] = x4;
}

int64_t idea_encrypt_decrypt(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 12) return -1;
    uint16_t key_words[8], block[4], subkeys[52], encrypted[4], recovered[4];
    for (size_t i = 0; i < 12; ++i) {
        if (input[i] < 0 || input[i] > 65535) return -1;
        if (i < 8) key_words[i] = (uint16_t)input[i];
        else block[i - 8] = (uint16_t)input[i];
    }
    if (output == NULL || capacity < 16) return -2;
    expand_key(key_words, subkeys);
    encrypt_block(subkeys, block, encrypted);
    decrypt_block(subkeys, encrypted, recovered);
    for (size_t i = 0; i < 4; ++i) {
        output[i * 2] = (uint8_t)encrypted[i]; output[i * 2 + 1] = (uint8_t)(encrypted[i] >> 8);
        output[8 + i * 2] = (uint8_t)recovered[i]; output[9 + i * 2] = (uint8_t)(recovered[i] >> 8);
    }
    return 16;
}
