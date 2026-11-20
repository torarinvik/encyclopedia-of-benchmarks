/* Uncompiled multiword bit-parallel LCS length draft. */
#include <stddef.h>
#include <stdint.h>
int64_t bit_parallel_lcs(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 515) return -1;
    int64_t nr = input[0], mr = input[1];
    if (nr < 0 || nr > 256 || mr < 0 || mr > 256 || length != (size_t)(2+nr+mr)) return -1;
    size_t n = (size_t)nr, m = (size_t)mr;
    for (size_t i = 2; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    uint64_t masks[256][4] = {{0}}, row[4] = {0};
    size_t words = (n+63)/64;
    for (size_t i = 0; i < n; ++i) masks[(size_t)input[2+i]][i/64] |= UINT64_C(1) << (i%64);
    for (size_t i = 0; i < m; ++i) {
        size_t symbol = (size_t)input[2+n+i];
        uint64_t carry = 1, borrow = 0;
        for (size_t j = 0; j < words; ++j) {
            uint64_t old = row[j], combined = old | masks[symbol][j];
            uint64_t shifted = (old << 1) | carry;
            carry = old >> 63;
            uint64_t partial = combined - shifted;
            uint64_t first_borrow = combined < shifted;
            uint64_t difference = partial - borrow;
            borrow = first_borrow | (partial < borrow);
            row[j] = combined & (combined ^ difference);
        }
    }
    int64_t result = 0;
    for (size_t j = 0; j < words; ++j) {
        uint64_t word = row[j];
        while (word) { word &= word-1; ++result; }
    }
    return result;
}
