module word_count;

fn void store_i64_le(long value, char* output, usz position) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[position + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

// Count literal-space-delimited words and requested-word matches.
fn long word_count(long* values, usz length, char* output, usz output_capacity)
        @export("word_count") {
    if (values == null || length < 2 || length > 1050) return -1;
    if (values[0] < 0 || values[0] > 999) return -1;
    usz text_length = (usz)values[0];
    usz query_index = 1 + text_length;
    if (query_index >= length || values[query_index] < 0 || values[query_index] > 49) return -1;
    usz query_length = (usz)values[query_index];
    if (length != query_index + 1 + query_length) return -1;
    for (usz i = 1; i < query_index; i++) if (values[i] < 1 || values[i] > 127) return -1;
    for (usz i = query_index + 1; i < length; i++) if (values[i] < 1 || values[i] > 127) return -1;
    usz total = 0, matches = 0, start = 0;
    for (usz end = 0; end <= text_length; end++) {
        if (end == text_length || values[1 + end] == 32) {
            usz token_length = end - start;
            if (token_length > 49) return -1;
            if (total >= 20) return -2;
            if (token_length == query_length) {
                usz offset = 0;
                while (offset < token_length && values[1 + start + offset] == values[query_index + 1 + offset]) offset++;
                if (offset == token_length) matches++;
            }
            total++;
            start = end + 1;
        }
    }
    if (output == null || output_capacity < 16) return -2;
    store_i64_le((long)total, output, 0);
    store_i64_le((long)matches, output, 8);
    return 16;
}
