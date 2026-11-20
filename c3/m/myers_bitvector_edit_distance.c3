// Uncompiled multiword bit-vector global edit-distance draft.
module myers_bitvector_edit_distance;
fn long myers_bitvector_edit_distance(long* input, usz length) @export("myers_bitvector_edit_distance") {
    if (input == null || length < 2 || length > 515) return -1;
    long nr = input[0], mr = input[1];
    if (nr < 0 || nr > 256 || mr < 0 || mr > 256 || length != (usz)(2+nr+mr)) return -1;
    usz n = (usz)nr, m = (usz)mr;
    for (usz i = 2; i < length; i++) if (input[i] < 0 || input[i] > 255) return -1;
    if (n == 0) return mr;
    ulong[4][256] masks = zeroed;
    ulong[4] pv = zeroed, mv = zeroed;
    usz words = (n+63)/64;
    for (usz j = 0; j < words; j++) pv[j] = ~(ulong)0;
    for (usz i = 0; i < n; i++) masks[(usz)input[2+i]][i/64] |= (ulong)1 << (i%64);
    long score = nr;
    ulong top = (ulong)1 << ((n-1)%64);
    for (usz i = 0; i < m; i++) {
        usz symbol = (usz)input[2+n+i];
        ulong add = 0, pc = 1, mc = 0;
        for (usz j = 0; j < words; j++) {
            ulong eq = masks[symbol][j], p = pv[j], v = mv[j];
            ulong term = eq & p, limit = ~(ulong)0;
            bool carry1 = p > limit-term;
            ulong first = carry1 ? p-(limit-term)-1 : p+term;
            bool carry2 = add != 0 && first == limit;
            ulong sum = carry2 ? 0 : first+add;
            add = carry1 || carry2 ? 1 : 0;
            ulong xh = (sum ^ p) | eq, xv = eq | v;
            ulong ph = v | ~(xh | p), mh = p & xh;
            if (j == words-1) { if ((ph & top) != 0) score++; if ((mh & top) != 0) score--; }
            ulong next_pc = ph >> 63, next_mc = mh >> 63;
            ph = (ph << 1) | pc; mh = (mh << 1) | mc;
            pc = next_pc; mc = next_mc;
            pv[j] = mh | ~(xv | ph); mv[j] = ph & xv;
        }
    }
    return score;
}
