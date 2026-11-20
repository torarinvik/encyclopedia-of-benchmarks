module tuned_boyer_moore_search;

const usz TUNED_MAX_TEXT = 255;
const usz TUNED_MAX_PATTERN = 64;
const usz TUNED_MAX_FRAME = 322;
const usz TUNED_ALPHABET = 128;
const usz TUNED_MAX_PADDED = 319;

fn void tuned_store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long tuned_boyer_moore_search(long* input, usz length, char* output, usz output_capacity)
        @export("tuned_boyer_moore_search") {
    if (input == null || length < 2 || length > TUNED_MAX_FRAME) return -1;
    if (input[0] < 0 || input[0] > (long)TUNED_MAX_TEXT ||
        input[1] < 1 || input[1] > (long)TUNED_MAX_PATTERN) return -1;
    usz n = (usz)input[0];
    usz m = (usz)input[1];
    if (length != 2 + n + m) return -1;
    for (usz i = 0; i < n + m; i++) if (input[2 + i] < 0 || input[2 + i] > 127) return -1;

    long[255] positions = zeroed;
    usz match_count = 0;
    if (m <= n) {
        char[319] padded = zeroed;
        usz[128] shifts = zeroed;
        usz pattern_start = 2 + n;
        char final_byte = (char)input[pattern_start + m - 1];
        for (usz i = 0; i < n; i++) padded[i] = (char)input[2 + i];
        for (usz i = 0; i < m; i++) padded[n + i] = final_byte;
        for (usz byte = 0; byte < TUNED_ALPHABET; byte++) shifts[byte] = m;
        for (usz i = 0; i + 1 < m; i++) shifts[(usz)input[pattern_start + i]] = m - i - 1;
        usz final_shift = shifts[(usz)final_byte];
        shifts[(usz)final_byte] = 0;
        usz alignment = 0;
        while (alignment < n) {
            usz skip = shifts[(usz)padded[alignment + m - 1]];
            while (skip != 0) {
                alignment += skip; skip = shifts[(usz)padded[alignment + m - 1]];
                alignment += skip; skip = shifts[(usz)padded[alignment + m - 1]];
                alignment += skip; skip = shifts[(usz)padded[alignment + m - 1]];
            }
            bool prefix_matches = true;
            for (usz i = 0; i + 1 < m; i++) {
                if ((long)padded[alignment + i] != input[pattern_start + i]) { prefix_matches = false; break; }
            }
            if (prefix_matches && alignment < n) positions[match_count++] = (long)alignment;
            alignment += final_shift;
        }
    }
    usz output_bytes = match_count * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz i = 0; i < match_count; i++) tuned_store_i64_le(output, i * 8, positions[i]);
    return (long)output_bytes;
}
