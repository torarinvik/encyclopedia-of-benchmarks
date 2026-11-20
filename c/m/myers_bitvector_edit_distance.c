/* Uncompiled multiword bit-vector global edit-distance draft. */
#include <stddef.h>
#include <stdint.h>

int64_t myers_bitvector_edit_distance(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 515) return -1;
    int64_t nr = input[0], mr = input[1];
    if (nr < 0 || nr > 256 || mr < 0 || mr > 256 ||
        length != (size_t)(2 + nr + mr)) return -1;
    size_t n = (size_t)nr, m = (size_t)mr;
    for (size_t i = 2; i < length; ++i)
        if (input[i] < 0 || input[i] > 255) return -1;
    if (n == 0) return (int64_t)m;
    uint64_t masks[256][4] = {{0}}, pv[4], mv[4] = {0};
    size_t words = (n + 63) / 64;
    for (size_t i = 0; i < words; ++i) pv[i] = UINT64_MAX;
    for (size_t i = 0; i < n; ++i)
        masks[(size_t)input[2+i]][i/64] |= UINT64_C(1) << (i%64);
    int64_t score = (int64_t)n;
    uint64_t top = UINT64_C(1) << ((n-1)%64);
    for (size_t i = 0; i < m; ++i) {
        size_t symbol = (size_t)input[2+n+i];
        uint64_t add_carry = 0, ph_carry = 1, mh_carry = 0;
        for (size_t j = 0; j < words; ++j) {
            uint64_t eq = masks[symbol][j], p = pv[j], v = mv[j];
            uint64_t term = eq & p;
            uint64_t first = term + p;
            uint64_t carry1 = first < term;
            uint64_t sum = first + add_carry;
            add_carry = carry1 | (sum < first);
            uint64_t xh = (sum ^ p) | eq;
            uint64_t xv = eq | v;
            uint64_t ph = v | ~(xh | p);
            uint64_t mh = p & xh;
            if (j == words-1) {
                if (ph & top) ++score;
                if (mh & top) --score;
            }
            uint64_t next_ph_carry = ph >> 63;
            uint64_t next_mh_carry = mh >> 63;
            ph = (ph << 1) | ph_carry;
            mh = (mh << 1) | mh_carry;
            ph_carry = next_ph_carry;
            mh_carry = next_mh_carry;
            pv[j] = mh | ~(xv | ph);
            mv[j] = ph & xv;
        }
    }
    return score;
}
