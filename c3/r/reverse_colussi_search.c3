module reverse_colussi_search;

const usz MAX_TEXT = 4096;
const usz MAX_PATTERN = 128;
const usz MAX_INPUT_LENGTH = 4227;

fn long reverse_colussi_search(long* input, usz length) @export("reverse_colussi_search") {
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
        long value = input[2 + q];
        if (value < 0 || value > 3) return -1;
        text[q] = (uchar)value;
    }
    for (usz q = 0; q < m; q++) {
        long value = input[2 + n + q];
        if (value < 0 || value > 3) return -1;
        pattern[q] = (uchar)value;
    }
    if (n < m) return 0;

    int[MAX_PATTERN + 1] hmin = {};
    int[MAX_PATTERN] kmin = {};
    int[MAX_PATTERN] rmin = {};
    int[MAX_PATTERN] order = {};
    int[MAX_PATTERN + 1] good_suffix = {};
    int[4][MAX_PATTERN + 1] bad_character = {};
    for (usz shift = 1; shift <= m; shift++) {
        int last_mismatch = (int)shift - 1;
        for (usz pos = shift; pos < m; pos++)
            if (pattern[pos] != pattern[pos - shift]) last_mismatch = (int)pos;
        hmin[shift] = last_mismatch;
    }
    int shift = (int)m;
    while (shift >= 1) {
        int end = hmin[shift];
        if ((usz)end != m - 1) kmin[end] = shift;
        shift--;
    }
    int next_boundary = (int)m;
    int end = (int)m - 1;
    while (end >= 0) {
        if (hmin[end + 1] == end) next_boundary = end + 1;
        rmin[end] = next_boundary;
        end--;
    }
    order[0] = (int)m - 1;
    int cursor = 0;
    for (usz q = 1; q <= m; q++) {
        int h_end = hmin[q];
        if ((usz)h_end != m - 1 && kmin[h_end] == (int)q) {
            cursor++;
            order[cursor] = h_end;
            good_suffix[cursor] = (int)q;
        }
    }
    cursor = (int)m - 1;
    end = (int)m - 2;
    while (end >= 0) {
        if (kmin[end] == 0) {
            order[cursor] = end;
            good_suffix[cursor] = rmin[end];
            cursor--;
        }
        end--;
    }
    good_suffix[m] = rmin[0];

    for (int symbol = 0; symbol < 4; symbol++) {
        for (usz prior_shift = 1; prior_shift <= m; prior_shift++) {
            int boundary = (int)m - (int)prior_shift - 1;
            for (usz q = 1; q <= m; q++) {
                int candidate = (int)q;
                if (q < m && pattern[m - q - 1] != (uchar)symbol) continue;
                if (candidate <= boundary &&
                    pattern[m - q - prior_shift - 1] != pattern[boundary]) continue;
                bad_character[symbol][prior_shift] = candidate;
                break;
            }
        }
    }

    long count = 0;
    long offset_sum = 0;
    long offset_xor = 0;
    int start = 0;
    int shift_state = (int)m;
    int last_start = (int)(n - m);
    while (start <= last_start) {
        while (start <= last_start && pattern[m - 1] != text[start + m - 1]) {
            shift_state = bad_character[text[start + m - 1]][shift_state];
            start += shift_state;
        }
        if (start > last_start) break;
        int index = 1;
        while ((usz)index < m && pattern[order[index]] == text[start + order[index]]) index++;
        if ((usz)index == m) {
            count++;
            offset_sum += start;
            offset_xor ^= start;
        }
        shift_state = good_suffix[index];
        start += shift_state;
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
