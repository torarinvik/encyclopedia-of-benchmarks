module zhu_takaoka_search;

const usz MAX_TEXT = 256;
const usz MAX_PATTERN = 16;
const usz ALPHABET = 16;

fn long zhu_takaoka_search(long* values, usz length) @export("zhu_takaoka_search") {
    if (values == null || length < 2 || length > 274) return -2;
    if (values[0] < 0 || values[0] > 256 || values[1] < 2 || values[1] > 16) return -2;
    usz n = (usz)values[0], m = (usz)values[1];
    if (length != 2 + n + m) return -2;
    for (usz i = 0; i < n + m; i++) if (values[2 + i] < 0 || values[2 + i] >= 16) return -2;
    if (m > n) return -1;

    usz p = 2 + n;
    usz[256] pair_shift;
    for (usz i = 0; i < 256; i++) pair_shift[i] = m;
    for (usz a = 0; a < ALPHABET; a++) pair_shift[a * ALPHABET + (usz)values[p]] = m - 1;
    for (usz i = 1; i + 1 < m; i++)
        pair_shift[(usz)values[p + i - 1] * ALPHABET + (usz)values[p + i]] = m - 1 - i;

    usz[MAX_PATTERN] good_suffix;
    for (usz mismatch = 0; mismatch < m; mismatch++) {
        good_suffix[mismatch] = m;
        for (usz shift = 1; shift <= m; shift++) {
            usz first_known = mismatch + 1 > shift ? mismatch + 1 : shift;
            usz position = first_known;
            while (position < m && values[p + position] == values[p + position - shift]) position++;
            if (position < m) continue;
            if (mismatch + 1 < m && shift <= mismatch && values[p + mismatch - shift] == values[p + mismatch]) continue;
            good_suffix[mismatch] = shift;
            break;
        }
    }

    usz start = 0;
    while (start <= n - m) {
        usz mismatch = m;
        while (mismatch > 0 && values[p + mismatch - 1] == values[2 + start + mismatch - 1]) mismatch--;
        if (mismatch == 0) return (long)start;
        mismatch--;
        usz first = (usz)values[2 + start + m - 2];
        usz second = (usz)values[2 + start + m - 1];
        usz pair = pair_shift[first * ALPHABET + second];
        start += good_suffix[mismatch] > pair ? good_suffix[mismatch] : pair;
    }
    return -1;
}
