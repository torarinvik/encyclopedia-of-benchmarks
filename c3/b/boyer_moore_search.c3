module boyer_moore_search;

// Return the first ASCII byte match using the bad-character rule.
fn long boyer_moore_search(long* input_values, usz length) @export("boyer_moore_search") {
    if (input_values == null || length < 2 || length > 8194) return -1;
    if (input_values[0] < 0 || input_values[0] > 4096 || input_values[1] < 0 || input_values[1] > 4096) return -1;
    usz text_length = (usz)input_values[0];
    usz pattern_length = (usz)input_values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (usz index = 0; index < text_length + pattern_length; index++) {
        if (input_values[2 + index] < 0 || input_values[2 + index] > 127) return -1;
    }
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    usz pattern_start = 2 + text_length;
    long[128] last_occurrence;
    for (usz value = 0; value < 128; value++) last_occurrence[value] = -1;
    for (usz index = 0; index < pattern_length; index++) {
        last_occurrence[(usz)input_values[pattern_start + index]] = (long)index;
    }

    usz alignment = 0;
    while (alignment <= text_length - pattern_length) {
        usz pattern_index = pattern_length;
        while (pattern_index > 0 &&
               input_values[pattern_start + pattern_index - 1] == input_values[2 + alignment + pattern_index - 1]) {
            pattern_index--;
        }
        if (pattern_index == 0) return (long)alignment;
        usz byte_index = (usz)input_values[2 + alignment + pattern_index - 1];
        long shift = (long)(pattern_index - 1) - last_occurrence[byte_index];
        if (shift < 1) shift = 1;
        alignment += (usz)shift;
    }
    return -1;
}
