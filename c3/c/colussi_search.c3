module colussi_search;

const COLUSSI_MAX_TEXT_LENGTH = 4096;
const COLUSSI_MAX_PATTERN_LENGTH = 128;
const COLUSSI_MAX_PARSEABLE_LENGTH = 4227;
const COLUSSI_TABLE_SIZE = COLUSSI_MAX_PATTERN_LENGTH + 1;

fn long colussi_preprocess(long* pattern, usz m, long* h, long* next,
                           long* shift) {
    long[COLUSSI_TABLE_SIZE] hmax = {0};
    long[COLUSSI_TABLE_SIZE] kmin = {0};
    long[COLUSSI_TABLE_SIZE] nhd0 = {0};
    long[COLUSSI_TABLE_SIZE] rmin = {0};
    long i = 1;
    long k = 1;

    while ((usz)k <= m) {
        while (pattern[i] == pattern[i - k]) i += 1;
        hmax[k] = i;
        long q = k + 1;
        while (hmax[q - k] + k < i) {
            hmax[q] = hmax[q - k] + k;
            q += 1;
        }
        k = q;
        if (k == i + 1) i = k;
    }

    for (usz index = 0; index <= m; index += 1) kmin[index] = 0;
    i = (long)m;
    while (i >= 1) {
        if ((usz)hmax[i] < m) kmin[hmax[i]] = i;
        i -= 1;
    }

    long r = (long)m;
    i = (long)m - 1;
    while (i >= 0) {
        if ((usz)hmax[i + 1] == m) r = i + 1;
        rmin[i] = kmin[i] == 0 ? r : 0;
        i -= 1;
    }

    long s = -1;
    r = (long)m;
    for (i = 0; (usz)i < m; i += 1) {
        if (kmin[i] == 0) {
            r -= 1;
            h[r] = i;
        } else {
            s += 1;
            h[s] = i;
        }
    }
    long nd = s;

    for (i = 0; i <= nd; i += 1) shift[i] = kmin[h[i]];
    for (i = nd + 1; (usz)i < m; i += 1) shift[i] = rmin[h[i]];
    shift[m] = rmin[0];

    s = 0;
    for (i = 0; (usz)i < m; i += 1) {
        nhd0[i] = s;
        if (kmin[i] > 0) s += 1;
    }

    for (i = 0; i <= nd; i += 1) next[i] = nhd0[h[i] - kmin[h[i]]];
    for (i = nd + 1; (usz)i < m; i += 1)
        next[i] = nhd0[(long)m - rmin[h[i]]];
    next[m] = nhd0[(long)m - rmin[h[m - 1]]];
    return nd;
}

fn long colussi_search(long* input, usz length)
    @export("colussi_search") {
    if (input == null || length < 2 || length > COLUSSI_MAX_PARSEABLE_LENGTH) {
        return -1;
    }
    long text_length_value = input[0];
    long pattern_length_value = input[1];
    if (text_length_value < 0 || text_length_value > COLUSSI_MAX_TEXT_LENGTH
        || pattern_length_value < 1
        || pattern_length_value > COLUSSI_MAX_PATTERN_LENGTH) {
        return -1;
    }
    usz n = (usz)text_length_value;
    usz m = (usz)pattern_length_value;
    if (length != 2 + n + m) return -1;

    usz pattern_start = 2 + n;
    long[COLUSSI_TABLE_SIZE] pattern = {0};
    for (usz index = 0; index < n; index += 1) {
        if (input[2 + index] < 0 || input[2 + index] > 3) return -1;
    }
    for (usz index = 0; index < m; index += 1) {
        long symbol = input[pattern_start + index];
        if (symbol < 0 || symbol > 3) return -1;
        pattern[index] = symbol;
    }
    pattern[m] = 4;

    long[COLUSSI_TABLE_SIZE] h = {0};
    long[COLUSSI_TABLE_SIZE] next = {0};
    long[COLUSSI_TABLE_SIZE] shift = {0};
    long nd = colussi_preprocess(&pattern[0], m, &h[0], &next[0], &shift[0]);

    long match_count = 0;
    long sum_offsets = 0;
    long xor_offsets = 0;
    if (n >= m) {
        long i = 0;
        long j = 0;
        long last = -1;
        while ((usz)j <= n - m) {
            while ((usz)i < m && last < j + h[i]
                   && pattern[h[i]] == input[2 + (usz)j + (usz)h[i]]) {
                i += 1;
            }
            if ((usz)i >= m) {
                match_count += 1;
                sum_offsets += j;
                xor_offsets ^= j;
                i = (long)m;
            } else if (last >= j + h[i]) {
                match_count += 1;
                sum_offsets += j;
                xor_offsets ^= j;
                i = (long)m;
            }
            if (i > nd) last = j + (long)m - 1;
            j += shift[i];
            i = next[i];
        }
    }

    return (match_count << 36) | (sum_offsets << 12) | xor_offsets;
}
