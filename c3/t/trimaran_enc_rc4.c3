// ARC4 port from Trimaran/enc-rc4, Copyright (C) 2001-2003 Christophe Devine.
// Distributed under GPL-2.0-or-later; see the package license notice.
module trimaran_enc_rc4;

const usz OUTPUT_BYTES = 82;
const usz MAX_PASSES = 2000;
const u8[48] KEYS = {0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef,
    0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef,
    0,0,0,0,0,0,0,0,
    0xef,0x01,0x23,0x45,0,0,0,0,
    0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef,
    0xef,0x01,0x23,0x45,0,0,0,0};
const u8[168] PLAINTEXTS = {
    0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef,
    0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,
    0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,
    0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,
    0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,
    0x12,0x34,0x56,0x78,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
const usz[6] KEY_LENGTHS = {8,8,8,4,8,4};
const usz[6] DATA_LENGTHS = {8,8,8,20,28,10};
const usz[6] OFFSETS = {0,8,16,24,44,72};

fn void crypt_one(u8* key, usz key_length, u8* data, usz length) {
    int[256] state = {};
    for (int i = 0; i < 256; i++) state[i] = i;
    int j = 0;
    for (int i = 0; i < 256; i++) {
        j = (j + state[i] + key[(usz)i % key_length]) & 255;
        int temp = state[i]; state[i] = state[j]; state[j] = temp;
    }
    int x = 0, y = 0;
    for (usz offset = 0; offset < length; offset++) {
        x = (x + 1) & 255;
        int a = state[x]; y = (y + a) & 255;
        int b = state[y]; state[x] = b; state[y] = a;
        data[offset] ^= (u8)state[(a + b) & 255];
    }
}

long trimaran_enc_rc4(long* input, usz length, char* output, usz output_capacity)
    @export("trimaran_enc_rc4") {
    if (input == null || length != 1 || input[0] < 1 || input[0] > (long)MAX_PASSES) return -1;
    if (output == null || output_capacity < OUTPUT_BYTES) return -2;
    u8[OUTPUT_BYTES] staged = {};
    for (usz pass = 0; pass < (usz)input[0]; pass++) {
        for (usz vector = 0; vector < 6; vector++) {
            usz offset = OFFSETS[vector];
            for (usz byte = 0; byte < DATA_LENGTHS[vector]; byte++)
                staged[offset + byte] = PLAINTEXTS[vector * 28 + byte];
            crypt_one(&KEYS[vector * 8], KEY_LENGTHS[vector], &staged[offset], DATA_LENGTHS[vector]);
        }
    }
    for (usz byte = 0; byte < OUTPUT_BYTES; byte++) output[byte] = (char)staged[byte];
    return (long)OUTPUT_BYTES;
}
