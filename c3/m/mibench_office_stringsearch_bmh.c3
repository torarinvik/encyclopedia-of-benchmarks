// Modified derivative of MiBench bmhsrch.c; case-sensitive BMH is public domain by Raymond Gardner (7/92).
module mibench_office_stringsearch_bmh;

const usz MAX_TEXT = 128;
const usz MAX_PATTERN = 32;
const usz MAX_INPUT = 2 + MAX_TEXT + MAX_PATTERN;

fn void store_i64_le(char* output, usz value) {
    for (usz i = 0; i < 8; i += 1) output[i] = (char)((value >> (8 * i)) & 255);
}

fn long mibench_office_stringsearch_bmh(long* input, usz length,
        char* output, usz output_capacity) @export("mibench_office_stringsearch_bmh") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long text_len_value = input[0];
    long pattern_len_value = input[1];
    if (text_len_value < 0 || text_len_value > (long)MAX_TEXT ||
        pattern_len_value < 1 || pattern_len_value > (long)MAX_PATTERN) return -1;
    usz text_len = (usz)text_len_value;
    usz pattern_len = (usz)pattern_len_value;
    if (length != 2 + text_len + pattern_len) return -1;
    char[MAX_TEXT] text;
    char[MAX_PATTERN] pattern;
    for (usz i = 0; i < text_len + pattern_len; i += 1) {
        long value = input[2 + i];
        if (value < 32 || value > 126) return -1;
        if (i < text_len) text[i] = (char)value;
        else pattern[i - text_len] = (char)value;
    }
    usz[256] shift;
    for (usz i = 0; i < 256; i += 1) shift[i] = pattern_len;
    for (usz i = 0; i + 1 < pattern_len; i += 1)
        shift[(usz)pattern[i]] = pattern_len - i - 1;
    long match = -1;
    if (pattern_len <= text_len) {
        usz start = 0;
        while (start <= text_len - pattern_len) {
            usz j = pattern_len;
            while (j > 0 && text[start + j - 1] == pattern[j - 1]) j -= 1;
            if (j == 0) { match = (long)start; break; }
            start += shift[(usz)text[start + pattern_len - 1]];
        }
    }
    if (output == null || output_capacity < 8) return -2;
    store_i64_le(output, (usz)match);
    return 8;
}
