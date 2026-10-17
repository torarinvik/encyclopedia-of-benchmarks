module poly1305;

const usz MAX_MESSAGE_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 98;
const ulong LIMB_MASK = 0x3ffffffUL;

fn uint load32_le(char* bytes, usz offset) {
    return (uint)(uchar)bytes[offset] | ((uint)(uchar)bytes[offset + 1] << 8) |
        ((uint)(uchar)bytes[offset + 2] << 16) | ((uint)(uchar)bytes[offset + 3] << 24);
}

fn void store32_le(char* output, usz offset, uint value) {
    for (usz byte = 0; byte < 4; byte++) output[offset + byte] = (char)(value >> (8 * byte));
}

fn void poly1305_tag(char* key, char* message, usz message_length, char* tag) {
    ulong r0 = (ulong)load32_le(key, 0) & 0x3ffffffUL;
    ulong r1 = ((ulong)load32_le(key, 3) >> 2) & 0x3ffff03UL;
    ulong r2 = ((ulong)load32_le(key, 6) >> 4) & 0x3ffc0ffUL;
    ulong r3 = ((ulong)load32_le(key, 9) >> 6) & 0x3f03fffUL;
    ulong r4 = ((ulong)load32_le(key, 12) >> 8) & 0x00fffffUL;
    ulong s1 = r1 * 5, s2 = r2 * 5, s3 = r3 * 5, s4 = r4 * 5;
    ulong h0 = 0, h1 = 0, h2 = 0, h3 = 0, h4 = 0;
    usz offset = 0;
    while (offset < message_length) {
        char[16] block;
        for (usz i = 0; i < 16; i++) block[i] = 0;
        usz block_length = message_length - offset;
        if (block_length > 16) block_length = 16;
        for (usz i = 0; i < block_length; i++) block[i] = message[offset + i];
        ulong high_bit = 1UL << 24;
        if (block_length < 16) { block[block_length] = 1; high_bit = 0; }
        h0 += (ulong)load32_le(&block[0], 0) & LIMB_MASK;
        h1 += ((ulong)load32_le(&block[0], 3) >> 2) & LIMB_MASK;
        h2 += ((ulong)load32_le(&block[0], 6) >> 4) & LIMB_MASK;
        h3 += ((ulong)load32_le(&block[0], 9) >> 6) & LIMB_MASK;
        h4 += ((ulong)load32_le(&block[0], 12) >> 8) | high_bit;
        ulong d0 = h0 * r0 + h1 * s4 + h2 * s3 + h3 * s2 + h4 * s1;
        ulong d1 = h0 * r1 + h1 * r0 + h2 * s4 + h3 * s3 + h4 * s2;
        ulong d2 = h0 * r2 + h1 * r1 + h2 * r0 + h3 * s4 + h4 * s3;
        ulong d3 = h0 * r3 + h1 * r2 + h2 * r1 + h3 * r0 + h4 * s4;
        ulong d4 = h0 * r4 + h1 * r3 + h2 * r2 + h3 * r1 + h4 * r0;
        ulong carry = d0 >> 26; h0 = d0 & LIMB_MASK;
        ulong q1 = d1 + carry; carry = q1 >> 26; h1 = q1 & LIMB_MASK;
        ulong q2 = d2 + carry; carry = q2 >> 26; h2 = q2 & LIMB_MASK;
        ulong q3 = d3 + carry; carry = q3 >> 26; h3 = q3 & LIMB_MASK;
        ulong q4 = d4 + carry; carry = q4 >> 26; h4 = q4 & LIMB_MASK;
        h0 += carry * 5;
        carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry;
        offset += block_length;
    }
    for (usz pass = 0; pass < 3; pass++) {
        ulong carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry;
        carry = h1 >> 26; h1 &= LIMB_MASK; h2 += carry;
        carry = h2 >> 26; h2 &= LIMB_MASK; h3 += carry;
        carry = h3 >> 26; h3 &= LIMB_MASK; h4 += carry;
        carry = h4 >> 26; h4 &= LIMB_MASK; h0 += carry * 5;
        carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry;
    }
    if (h4 == LIMB_MASK && h3 == LIMB_MASK && h2 == LIMB_MASK && h1 == LIMB_MASK && h0 >= LIMB_MASK - 4) {
        h0 -= LIMB_MASK - 4; h1 = 0; h2 = 0; h3 = 0; h4 = 0;
    }
    ulong f0 = ((h0 | (h1 << 26)) & 0xffffffffUL) + load32_le(key, 16);
    ulong f1 = ((h1 >> 6 | (h2 << 20)) & 0xffffffffUL) + load32_le(key, 20) + (f0 >> 32);
    ulong f2 = ((h2 >> 12 | (h3 << 14)) & 0xffffffffUL) + load32_le(key, 24) + (f1 >> 32);
    ulong f3 = ((h3 >> 18 | (h4 << 8)) & 0xffffffffUL) + load32_le(key, 28) + (f2 >> 32);
    store32_le(tag, 0, (uint)f0); store32_le(tag, 4, (uint)f1);
    store32_le(tag, 8, (uint)f2); store32_le(tag, 12, (uint)f3);
}

fn long poly1305(long* input, usz length, char* output, usz output_capacity) @export("poly1305") {
    if (input == null || length < 33 || length > MAX_INPUT_LENGTH) return -1;
    long raw_length = input[0];
    if (raw_length < 0 || raw_length > (long)MAX_MESSAGE_LENGTH || length != 33 + (usz)raw_length) return -1;
    for (usz i = 1; i < length; i++) if (input[i] < 0 || input[i] > 255) return -1;
    if (output == null || output_capacity < 16) return -2;
    char[32] key;
    char[MAX_MESSAGE_LENGTH] message;
    char[16] tag;
    for (usz i = 0; i < 32; i++) key[i] = (char)input[1 + i];
    for (usz i = 0; i < (usz)raw_length; i++) message[i] = (char)input[33 + i];
    poly1305_tag(&key[0], &message[0], (usz)raw_length, &tag[0]);
    for (usz i = 0; i < 16; i++) output[i] = tag[i];
    return 16;
}
