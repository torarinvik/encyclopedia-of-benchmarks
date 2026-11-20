module morris_pratt_search;

const usz MAX_TEXT = 4096;
const usz MAX_PATTERN = 128;
const usz MAX_INPUT = 4227;

fn long morris_pratt_search(long* input, usz length) @export("morris_pratt_search") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > (long)MAX_TEXT || m64 < 1 || m64 > (long)MAX_PATTERN) return -1;
    usz n = (usz)n64, m = (usz)m64;
    if (length != 2 + n + m) return -1;
    usz pattern_start = 2 + n;
    for (usz q = 0; q < n + m; q++)
        if (input[2 + q] < 0 || input[2 + q] > 3) return -1;

    long[129] mp_next;
    mp_next[0] = -1;
    for (usz index = 0; index < m; index++) {
        long border = mp_next[index];
        while (border >= 0 && input[pattern_start + index] != input[pattern_start + (usz)border])
            border = mp_next[(usz)border];
        mp_next[index + 1] = border + 1;
    }

    long matched = 0, count = 0, offset_sum = 0, offset_xor = 0;
    for (usz text_index = 0; text_index < n; text_index++) {
        while (matched >= 0 && input[pattern_start + (usz)matched] != input[2 + text_index])
            matched = mp_next[(usz)matched];
        matched++;
        if ((usz)matched == m) {
            long start = (long)(text_index + 1) - matched;
            count++;
            offset_sum += start;
            offset_xor ^= start;
            matched = mp_next[m];
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
