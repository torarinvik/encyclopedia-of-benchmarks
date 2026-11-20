// Uncompiled multiword bit-parallel LCS length draft.
module bit_parallel_lcs;
fn long bit_parallel_lcs(long* input, usz length) @export("bit_parallel_lcs") {
    if (input == null || length < 2 || length > 515) return -1;
    long nr = input[0], mr = input[1];
    if (nr < 0 || nr > 256 || mr < 0 || mr > 256 || length != (usz)(2+nr+mr)) return -1;
    usz n = (usz)nr, m = (usz)mr;
    for (usz i = 2; i < length; i++) if (input[i] < 0 || input[i] > 255) return -1;
    ulong[4][256] masks = zeroed;
    ulong[4] row = zeroed;
    usz words = (n+63)/64;
    for (usz i = 0; i < n; i++) masks[(usz)input[2+i]][i/64] |= (ulong)1 << (i%64);
    for (usz i = 0; i < m; i++) {
        usz symbol = (usz)input[2+n+i];
        ulong carry = 1, borrow = 0;
        for (usz j = 0; j < words; j++) {
            ulong old = row[j], combined = old | masks[symbol][j];
            ulong shifted = (old << 1) | carry; carry = old >> 63;
            bool first_borrow = combined < shifted;
            ulong partial = first_borrow ? ~(shifted-combined)+1 : combined-shifted;
            bool second_borrow = partial < borrow;
            ulong difference = second_borrow ? ~(ulong)0 : partial-borrow;
            borrow = first_borrow || second_borrow ? 1 : 0;
            row[j] = combined & (combined ^ difference);
        }
    }
    long result = 0;
    for (usz j = 0; j < words; j++) {
        ulong word = row[j];
        while (word != 0) { word &= word-1; result++; }
    }
    return result;
}
