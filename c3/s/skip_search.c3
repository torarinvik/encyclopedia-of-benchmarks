module skip_search;

const usz MAX_TEXT = 4096;
const usz MAX_PATTERN = 128;
const usz MAX_INPUT = 4227;
const usz ALPHABET = 4;

fn long skip_search(long* input, usz length) @export("skip_search") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > (long)MAX_TEXT || m64 < 1 || m64 > (long)MAX_PATTERN) return -1;
    usz n = (usz)n64, m = (usz)m64;
    if (length != 2 + n + m) return -1;

    uchar[MAX_TEXT] text = zeroed;
    uchar[MAX_PATTERN] pattern = zeroed;
    for (usz q = 0; q < n; q++) {
        long value = input[2 + q];
        if (value < 0 || value >= (long)ALPHABET) return -1;
        text[q] = (uchar)value;
    }
    int[ALPHABET * MAX_PATTERN] positions = zeroed;
    int[ALPHABET] bucket_size = zeroed;
    for (usz q = 0; q < m; q++) {
        long value = input[2 + n + q];
        if (value < 0 || value >= (long)ALPHABET) return -1;
        pattern[q] = (uchar)value;
        usz symbol = (usz)value;
        positions[symbol * MAX_PATTERN + (usz)bucket_size[symbol]] = (int)q;
        bucket_size[symbol]++;
    }

    long count = 0, offset_sum = 0, offset_xor = 0;
    for (usz sample = m - 1; sample < n; sample += m) {
        usz symbol = (usz)text[sample];
        for (int item = 0; item < bucket_size[symbol]; item++) {
            int start = (int)sample - positions[symbol * MAX_PATTERN + (usz)item];
            if (start < 0 || (usz)start > n - m) continue;
            int matched = 0;
            while ((usz)matched < m && text[(usz)start + (usz)matched] == pattern[(usz)matched]) matched++;
            if ((usz)matched == m) {
                count++;
                offset_sum += (long)start;
                offset_xor ^= (long)start;
            }
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
