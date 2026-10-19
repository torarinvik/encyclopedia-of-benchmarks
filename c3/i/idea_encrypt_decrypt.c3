module idea_encrypt_decrypt;

fn ushort idea_mul(ushort left, ushort right) {
    ulong a = left == 0 ? 65536 : (ulong)left;
    ulong b = right == 0 ? 65536 : (ulong)right;
    ulong residue = (a * b) % 65537;
    return residue == 65536 ? 0 : (ushort)residue;
}

fn ushort idea_inverse(ushort value) {
    long old_r = 65537, r = value == 0 ? 65536 : (long)value;
    long old_s = 0, s = 1;
    while (r != 0) {
        long quotient = old_r / r;
        long next_r = old_r - quotient * r;
        long next_s = old_s - quotient * s;
        old_r = r; r = next_r; old_s = s; s = next_s;
    }
    old_s %= 65537;
    if (old_s < 0) old_s += 65537;
    return old_s == 65536 ? 0 : (ushort)old_s;
}

fn ushort add16(ushort a, ushort b) { return (ushort)(((uint)a + (uint)b) & 65535); }
fn ushort sub16(ushort a, ushort b) { return (ushort)(((uint)a - (uint)b) & 65535); }

fn void expand_key(ushort* key, ushort* subkeys) {
    ushort[8] state;
    for (usz i = 0; i < 8; i++) state[i] = key[i];
    for (usz offset = 0; offset < 52; offset += 8) {
        usz amount = 52 - offset < 8 ? 52 - offset : 8;
        for (usz i = 0; i < amount; i++) subkeys[offset + i] = state[i];
        ushort[8] rotated;
        for (usz i = 0; i < 8; i++) rotated[i] = (ushort)((state[(i + 1) & 7] << 9) | (state[(i + 2) & 7] >> 7));
        state = rotated;
    }
}

fn void encrypt_block(ushort* key, ushort* plain, ushort* cipher) {
    ushort x1 = plain[0], x2 = plain[1], x3 = plain[2], x4 = plain[3];
    for (usz round = 0; round < 8; round++) {
        usz k = round * 6;
        ushort a = idea_mul(x1, key[k]);
        ushort b = add16(x2, key[k + 1]), c = add16(x3, key[k + 2]);
        ushort d = idea_mul(x4, key[k + 3]);
        ushort p = idea_mul(a ^ c, key[k + 4]);
        ushort q = idea_mul(add16(b ^ d, p), key[k + 5]);
        ushort r = add16(p, q);
        x1 = a ^ q; x2 = c ^ q; x3 = b ^ r; x4 = d ^ r;
    }
    cipher[0] = idea_mul(x1, key[48]); cipher[1] = add16(x3, key[49]);
    cipher[2] = add16(x2, key[50]); cipher[3] = idea_mul(x4, key[51]);
}

fn void decrypt_block(ushort* key, ushort* cipher, ushort* plain) {
    ushort x1 = idea_mul(cipher[0], idea_inverse(key[48]));
    ushort x2 = sub16(cipher[2], key[50]), x3 = sub16(cipher[1], key[49]);
    ushort x4 = idea_mul(cipher[3], idea_inverse(key[51]));
    for (usz step = 8; step > 0; step--) {
        usz k = (step - 1) * 6;
        ushort p = idea_mul(x1 ^ x2, key[k + 4]);
        ushort q = idea_mul(add16(x3 ^ x4, p), key[k + 5]);
        ushort r = add16(p, q);
        ushort a = x1 ^ q, c = x2 ^ q, b = x3 ^ r, d = x4 ^ r;
        x1 = idea_mul(a, idea_inverse(key[k])); x2 = sub16(b, key[k + 1]);
        x3 = sub16(c, key[k + 2]); x4 = idea_mul(d, idea_inverse(key[k + 3]));
    }
    plain[0] = x1; plain[1] = x2; plain[2] = x3; plain[3] = x4;
}

fn void write_word_le(char* output, usz offset, ushort value) {
    output[offset] = (char)value;
    output[offset + 1] = (char)(value >> 8);
}

fn long idea_encrypt_decrypt(long* input, usz length, char* output, usz capacity)
    @export("idea_encrypt_decrypt") {
    if (input == null || length != 12) return -1;
    ushort[8] key_words;
    ushort[4] block;
    for (usz i = 0; i < 12; i++) {
        if (input[i] < 0 || input[i] > 65535) return -1;
        if (i < 8) key_words[i] = (ushort)input[i]; else block[i - 8] = (ushort)input[i];
    }
    if (output == null || capacity < 16) return -2;
    ushort[52] keys;
    ushort[4] encrypted, recovered;
    expand_key(&key_words[0], &keys[0]);
    encrypt_block(&keys[0], &block[0], &encrypted[0]);
    decrypt_block(&keys[0], &encrypted[0], &recovered[0]);
    for (usz i = 0; i < 4; i++) { write_word_le(output, i * 2, encrypted[i]); write_word_le(output, 8 + i * 2, recovered[i]); }
    return 16;
}
