#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 64, MAX_OPERATIONS = 64, MAX_TOTAL = 65, MAX_INPUT = 195, ALPHABET = 5 };

static int suffix_less(const int64_t *s, size_t n, size_t a, size_t b) {
    while (a < n && b < n) {
        if (s[a] != s[b]) return s[a] < s[b];
        ++a;
        ++b;
    }
    return a == n && b != n;
}

static void build_index(const int64_t *s, size_t total, size_t cumulative[ALPHABET],
                        int64_t *bwt) {
    size_t suffixes[MAX_TOTAL];
    size_t frequency[ALPHABET] = {0};
    for (size_t i = 0; i < total; ++i) suffixes[i] = i;
    for (size_t i = 1; i < total; ++i) {
        size_t key = suffixes[i], j = i;
        while (j > 0 && suffix_less(s, total, key, suffixes[j - 1])) {
            suffixes[j] = suffixes[j - 1];
            --j;
        }
        suffixes[j] = key;
    }
    for (size_t i = 0; i < total; ++i) {
        bwt[i] = s[(suffixes[i] + total - 1) % total];
        ++frequency[(size_t)bwt[i]];
    }
    size_t seen = 0;
    for (size_t symbol = 0; symbol < ALPHABET; ++symbol) {
        cumulative[symbol] = seen;
        seen += frequency[symbol];
    }
}

static size_t rank_before(const int64_t *bwt, size_t end, size_t symbol) {
    size_t count = 0;
    for (size_t i = 0; i < end; ++i) if ((size_t)bwt[i] == symbol) ++count;
    return count;
}

int64_t bidirectional_fm_index(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n0 = input[0], q0 = input[1];
    if (n0 < 0 || n0 > MAX_TEXT || q0 < 0 || q0 > MAX_OPERATIONS) return -1;
    const size_t n = (size_t)n0, q = (size_t)q0;
    if (length != 2 + n + 2 * q) return -1;
    int64_t forward_text[MAX_TOTAL], reverse_text[MAX_TOTAL];
    for (size_t i = 0; i < n; ++i) {
        const int64_t symbol = input[2 + i];
        if (symbol < 1 || symbol > 4) return -1;
        forward_text[i] = symbol;
        reverse_text[n - 1 - i] = symbol;
    }
    forward_text[n] = 0;
    reverse_text[n] = 0;
    for (size_t i = 0; i < q; ++i) {
        const int64_t side = input[2 + n + 2 * i];
        const int64_t symbol = input[3 + n + 2 * i];
        if ((side != 0 && side != 1) || symbol < 1 || symbol > 4) return -1;
    }

    const size_t total = n + 1;
    size_t forward_c[ALPHABET], reverse_c[ALPHABET];
    int64_t forward_bwt[MAX_TOTAL] = {0}, reverse_bwt[MAX_TOTAL] = {0};
    build_index(forward_text, total, forward_c, forward_bwt);
    build_index(reverse_text, total, reverse_c, reverse_bwt);

    size_t fl = 0, fr = total, rl = 0, rr = total;
    int64_t checksum = 0;
    for (size_t op = 0; op < q; ++op) {
        const size_t side = (size_t)input[2 + n + 2 * op];
        const size_t symbol = (size_t)input[3 + n + 2 * op];
        const size_t old_fl = fl, old_fr = fr, old_rl = rl, old_rr = rr;
        if (side == 0) {
            fl = forward_c[symbol] + rank_before(forward_bwt, old_fl, symbol);
            fr = forward_c[symbol] + rank_before(forward_bwt, old_fr, symbol);
            size_t start = old_rl;
            for (size_t smaller = 0; smaller < symbol; ++smaller)
                start += rank_before(forward_bwt, old_fr, smaller) - rank_before(forward_bwt, old_fl, smaller);
            const size_t count = rank_before(forward_bwt, old_fr, symbol) - rank_before(forward_bwt, old_fl, symbol);
            rl = start;
            rr = start + count;
        } else {
            rl = reverse_c[symbol] + rank_before(reverse_bwt, old_rl, symbol);
            rr = reverse_c[symbol] + rank_before(reverse_bwt, old_rr, symbol);
            size_t start = old_fl;
            for (size_t smaller = 0; smaller < symbol; ++smaller)
                start += rank_before(reverse_bwt, old_rr, smaller) - rank_before(reverse_bwt, old_rl, smaller);
            const size_t count = rank_before(reverse_bwt, old_rr, symbol) - rank_before(reverse_bwt, old_rl, symbol);
            fl = start;
            fr = start + count;
        }
        checksum += (int64_t)(op + 1) * (int64_t)(fr - fl);
    }
    return checksum;
}
