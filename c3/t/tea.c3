module tea;

const uint DELTA = 0x9E3779B9;
const uint DECRYPT_SUM = 0xC6EF3720;

fn ulong combine_words(uint low, uint high) {
    return ((ulong)high << 32) | (ulong)low;
}

fn ulong tea_encrypt(ulong block, ulong key0, ulong key1) {
    uint b0 = (uint)block;
    uint b1 = (uint)(block >> 32);
    uint k0 = (uint)key0;
    uint k1 = (uint)(key0 >> 32);
    uint k2 = (uint)key1;
    uint k3 = (uint)(key1 >> 32);
    uint sum = 0;
    for (usz round = 0; round < 32; round += 1) {
        sum += DELTA;
        b0 += ((b1 << 4) + k0) ^ (b1 + sum) ^ ((b1 >> 5) + k1);
        b1 += ((b0 << 4) + k2) ^ (b0 + sum) ^ ((b0 >> 5) + k3);
    }
    return ((ulong)b1 << 32) | (ulong)b0;
}

fn ulong tea_decrypt(ulong block, ulong key0, ulong key1) {
    uint b0 = (uint)block;
    uint b1 = (uint)(block >> 32);
    uint k0 = (uint)key0;
    uint k1 = (uint)(key0 >> 32);
    uint k2 = (uint)key1;
    uint k3 = (uint)(key1 >> 32);
    uint sum = DECRYPT_SUM;
    for (usz round = 0; round < 32; round += 1) {
        b1 -= ((b0 << 4) + k2) ^ (b0 + sum) ^ ((b0 >> 5) + k3);
        b0 -= ((b1 << 4) + k0) ^ (b1 + sum) ^ ((b1 >> 5) + k1);
        sum -= DELTA;
    }
    return ((ulong)b1 << 32) | (ulong)b0;
}

fn void store_u64_le(char* output, usz offset, ulong value) {
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)(value >> (byte * 8));
}

// Return ciphertext and the decrypted round-trip block as little-endian u64s.
fn long tea(long* input, usz length, char* output, usz output_capacity)
    @export("tea") {
    if (input == null || length != 6) return -1;
    for (usz index = 0; index < 6; index += 1)
        if (input[index] < -2147483648L || input[index] > 2147483647L) return -1;
    if (output == null || output_capacity < 16) return -2;
    uint block_low = (uint)(int)input[0];
    uint block_high = (uint)(int)input[1];
    uint key0_low = (uint)(int)input[2];
    uint key0_high = (uint)(int)input[3];
    uint key1_low = (uint)(int)input[4];
    uint key1_high = (uint)(int)input[5];
    ulong block = combine_words(block_low, block_high);
    ulong key0 = combine_words(key0_low, key0_high);
    ulong key1 = combine_words(key1_low, key1_high);
    ulong ciphertext = tea_encrypt(block, key0, key1);
    ulong recovered = tea_decrypt(ciphertext, key0, key1);
    store_u64_le(output, 0, ciphertext);
    store_u64_le(output, 8, recovered);
    return 16;
}
