module kmp_skip_search;

const usz MAX_TEXT = 4096;
const usz MAX_PATTERN = 128;
const usz MAX_INPUT_LENGTH = 4227;

fn bool advance_sample(uchar* text, usz n, usz m, int[4] last,
                       int* sample, int* position) {
    do {
        *sample += (int)m;
    } while ((usz)(*sample) < n && last[text[(usz)(*sample)]] < 0);
    if ((usz)(*sample) >= n) return false;
    *position = last[text[(usz)(*sample)]];
    return true;
}

fn long kmp_skip_search(long* input, usz length) @export("kmp_skip_search") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n64 = input[0];
    long m64 = input[1];
    if (n64 < 0 || n64 > (long)MAX_TEXT || m64 < 1 || m64 > (long)MAX_PATTERN) return -1;
    usz n = (usz)n64;
    usz m = (usz)m64;
    if (length != 2 + n + m) return -1;

    uchar[MAX_TEXT] text = zeroed;
    uchar[MAX_PATTERN] pattern = zeroed;
    for (usz q = 0; q < n; q++) {
        long symbol = input[2 + q];
        if (symbol < 0 || symbol > 3) return -1;
        text[q] = (uchar)symbol;
    }
    for (usz q = 0; q < m; q++) {
        long symbol = input[2 + n + q];
        if (symbol < 0 || symbol > 3) return -1;
        pattern[q] = (uchar)symbol;
    }
    if (n < m) return 0;

    int[MAX_PATTERN + 1] mp_next = {};
    int[MAX_PATTERN + 1] kmp_next = {};
    int q = 0;
    int border = -1;
    mp_next[0] = -1;
    while ((usz)q < m) {
        while (border >= 0 && pattern[q] != pattern[border]) border = mp_next[border];
        q++;
        border++;
        mp_next[q] = border;
    }
    q = 0;
    border = -1;
    kmp_next[0] = -1;
    while ((usz)q < m) {
        while (border >= 0 && pattern[q] != pattern[border]) border = kmp_next[border];
        q++;
        border++;
        if ((usz)q < m && pattern[q] == pattern[border]) kmp_next[q] = kmp_next[border];
        else kmp_next[q] = border;
    }

    int[4] last = {-1, -1, -1, -1};
    int[MAX_PATTERN] previous = {};
    for (usz q = 0; q < m; q++) {
        previous[q] = last[pattern[q]];
        last[pattern[q]] = (int)q;
    }

    int sample = -1;
    int i = -1;
    if (!advance_sample(&text, n, m, last, &sample, &i)) return 0;
    int start = sample - i;
    int wall = 0;
    int period = (int)m - kmp_next[m];
    long count = 0;
    long offset_sum = 0;
    long offset_xor = 0;
    while ((usz)start <= n - m) {
        if (start > wall) wall = start;
        int k = wall - start;
        while ((usz)k < m && pattern[k] == text[start + k]) k++;
        wall = start + k;
        if ((usz)k == m) {
            count++;
            offset_sum += (long)start;
            offset_xor ^= (long)start;
            i -= period;
        } else {
            i = previous[i];
        }
        if (i < 0 && !advance_sample(&text, n, m, last, &sample, &i)) break;

        int kmp_start = start + k - kmp_next[k];
        k = kmp_next[k];
        start = sample - i;
        while (start < kmp_start || (kmp_start < start && start < wall)) {
            if (start < kmp_start) {
                i = previous[i];
                if (i < 0 && !advance_sample(&text, n, m, last, &sample, &i)) return
                    (count << 36) | (offset_sum << 12) | offset_xor;
                start = sample - i;
            } else {
                kmp_start += k - mp_next[k];
                k = mp_next[k];
            }
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
