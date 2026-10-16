module blake2b;

const usz MAX_INPUT = 4096;
const usz BLOCK_BYTES = 128;
const ulong[8] IV = {
    0x6a09e667f3bcc908,0xbb67ae8584caa73b,0x3c6ef372fe94f82b,0xa54ff53a5f1d36f1,
    0x510e527fade682d1,0x9b05688c2b3e6c1f,0x1f83d9abfb41bd6b,0x5be0cd19137e2179
};
const char[160] SIGMA = {
    0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
    14,10,4,8,9,15,13,6,1,12,0,2,11,7,5,3,
    11,8,12,0,5,2,15,13,10,14,3,6,7,1,9,4,
    7,9,3,1,13,12,11,14,2,6,5,10,4,0,15,8,
    9,0,5,7,2,4,10,15,14,1,11,12,6,8,3,13,
    2,12,6,10,0,11,8,3,4,13,7,5,15,14,1,9,
    12,5,1,15,14,13,4,10,0,7,6,3,9,2,8,11,
    13,11,7,14,12,1,3,9,5,0,15,4,8,6,2,10,
    6,15,14,9,11,3,0,8,12,2,13,7,1,4,10,5,
    10,2,8,4,7,6,1,5,15,11,9,14,3,12,13,0
};

fn ulong rotr64(ulong value, uint amount) {
    return (value >> amount) | (value << (64 - amount));
}
fn void mix(ulong* v, usz a, usz b, usz c, usz d, ulong x, ulong y) {
    v[a] = v[a] + v[b] + x; v[d] = rotr64(v[d] ^ v[a], 32);
    v[c] += v[d]; v[b] = rotr64(v[b] ^ v[c], 24);
    v[a] = v[a] + v[b] + y; v[d] = rotr64(v[d] ^ v[a], 16);
    v[c] += v[d]; v[b] = rotr64(v[b] ^ v[c], 63);
}
fn ulong load_le64(char* block, usz position) {
    ulong value = 0;
    for (usz i = 0; i < 8; i++) value |= ((ulong)(block[position + i] & 0xff)) << (8 * i);
    return value;
}
fn void compress(ulong* h, char* block, ulong counter, bool is_last) {
    ulong[16] m;
    ulong[16] v;
    for (usz i = 0; i < 16; i++) m[i] = load_le64(block, i * 8);
    for (usz i = 0; i < 8; i++) { v[i] = h[i]; v[i + 8] = IV[i]; }
    v[12] ^= counter;
    if (is_last) v[14] = ~v[14];
    for (usz round = 0; round < 12; round++) {
        usz s = (round % 10) * 16;
        mix(&v[0],0,4,8,12,m[SIGMA[s]],m[SIGMA[s+1]]);
        mix(&v[0],1,5,9,13,m[SIGMA[s+2]],m[SIGMA[s+3]]);
        mix(&v[0],2,6,10,14,m[SIGMA[s+4]],m[SIGMA[s+5]]);
        mix(&v[0],3,7,11,15,m[SIGMA[s+6]],m[SIGMA[s+7]]);
        mix(&v[0],0,5,10,15,m[SIGMA[s+8]],m[SIGMA[s+9]]);
        mix(&v[0],1,6,11,12,m[SIGMA[s+10]],m[SIGMA[s+11]]);
        mix(&v[0],2,7,8,13,m[SIGMA[s+12]],m[SIGMA[s+13]]);
        mix(&v[0],3,4,9,14,m[SIGMA[s+14]],m[SIGMA[s+15]]);
    }
    for (usz i = 0; i < 8; i++) h[i] ^= v[i] ^ v[i + 8];
}

fn long blake2b(long* input, usz length, char* output, usz capacity) @export("blake2b") {
    if (length > MAX_INPUT || (length > 0 && input == null)) return -1;
    for (usz i = 0; i < length; i++) if (input[i] < 0 || input[i] > 255) return -1;
    if (output == null || capacity < 64) return -2;
    ulong[8] h = {IV[0],IV[1],IV[2],IV[3],IV[4],IV[5],IV[6],IV[7]};
    h[0] ^= 0x01010040;
    char[BLOCK_BYTES] block;
    for (usz i = 0; i < BLOCK_BYTES; i++) block[i] = 0;
    usz consumed = 0;
    ulong counter = 0;
    while (length - consumed > BLOCK_BYTES) {
        for (usz i = 0; i < BLOCK_BYTES; i++) block[i] = (char)input[consumed + i];
        counter += BLOCK_BYTES;
        compress(&h[0], &block[0], counter, false);
        consumed += BLOCK_BYTES;
        for (usz i = 0; i < BLOCK_BYTES; i++) block[i] = 0;
    }
    usz remaining = length - consumed;
    for (usz i = 0; i < remaining; i++) block[i] = (char)input[consumed + i];
    counter += remaining;
    compress(&h[0], &block[0], counter, true);
    for (usz word = 0; word < 8; word++) {
        for (usz byte = 0; byte < 8; byte++) output[word * 8 + byte] = (char)(h[word] >> (8 * byte));
    }
    return 64;
}
