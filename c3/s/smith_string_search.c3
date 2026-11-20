module smith_string_search;

const usz SMITH_MAX_TEXT = 255;
const usz SMITH_MAX_PATTERN = 64;
const usz SMITH_MAX_FRAME = 322;
const usz SMITH_ALPHABET = 128;

fn void smith_store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long smith_string_search(long* input, usz length, char* output, usz output_capacity)
        @export("smith_string_search") {
    if (input == null || length < 2 || length > SMITH_MAX_FRAME) return -1;
    if (input[0] < 0 || input[0] > (long)SMITH_MAX_TEXT ||
        input[1] < 1 || input[1] > (long)SMITH_MAX_PATTERN) return -1;
    usz n = (usz)input[0];
    usz m = (usz)input[1];
    if (length != 2 + n + m) return -1;
    for (usz i = 0; i < n + m; i++) if (input[2 + i] < 0 || input[2 + i] > 127) return -1;

    long[255] positions = zeroed;
    usz match_count = 0;
    if (m <= n) {
        usz pattern_start = 2 + n;
        usz[128] horspool = zeroed;
        usz[128] quick_search = zeroed;
        for (usz byte = 0; byte < SMITH_ALPHABET; byte++) {
            horspool[byte] = m;
            quick_search[byte] = m + 1;
        }
        for (usz i = 0; i + 1 < m; i++) horspool[(usz)input[pattern_start + i]] = m - i - 1;
        for (usz i = 0; i < m; i++) quick_search[(usz)input[pattern_start + i]] = m - i;
        usz alignment = 0;
        usz last_alignment = n - m;
        while (alignment <= last_alignment) {
            bool matches = true;
            for (usz i = 0; i < m; i++) {
                if (input[pattern_start + i] != input[2 + alignment + i]) { matches = false; break; }
            }
            if (matches) positions[match_count++] = (long)alignment;
            usz end_byte = (usz)input[2 + alignment + m - 1];
            usz lookahead = alignment + m;
            usz quick_shift = lookahead < n ? quick_search[(usz)input[2 + lookahead]] : m + 1;
            usz end_shift = horspool[end_byte];
            alignment += end_shift > quick_shift ? end_shift : quick_shift;
        }
    }
    usz output_bytes = match_count * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz i = 0; i < match_count; i++) smith_store_i64_le(output, i * 8, positions[i]);
    return (long)output_bytes;
}
