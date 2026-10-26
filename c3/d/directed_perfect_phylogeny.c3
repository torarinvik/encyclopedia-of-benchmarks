module directed_perfect_phylogeny;

fn long directed_perfect_phylogeny(long* input, usz length, uint8* output, usz capacity) @export("directed_perfect_phylogeny") {
    if (input == null || length < 3 || length > 146) return -1;
    long n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 12 || m0 < 1 || m0 > 12 || length != 2 + (usz)(n0 * m0)) return -1;
    usz n = (usz)n0, m = (usz)m0;
    uint16[12] sets;
    for (usz row = 0; row < n; row++) for (usz col = 0; col < m; col++) {
        long bit = input[2 + row * m + col];
        if (bit != 0 && bit != 1) return -1;
        if (bit == 1) sets[col] |= (uint16)1 << (uint16)row;
    }
    bool feasible = true;
    for (usz a = 0; a < m; a++) for (usz b = a + 1; b < m; b++) {
        uint16 overlap = sets[a] & sets[b];
        if (overlap != 0 && overlap != sets[a] && overlap != sets[b]) feasible = false;
    }
    if (output == null || capacity < 8) return -2;
    ulong bits = feasible ? 1ul : 0ul;
    for (usz b = 0; b < 8; b++) output[b] = (uint8)(bits >> (8 * b));
    return 8;
}
