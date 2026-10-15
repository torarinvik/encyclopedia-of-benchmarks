module boyer_moore;

// Return the first ASCII byte match using bad-character and good-suffix shifts.
fn long boyer_moore(long* values, usz length) @export("boyer_moore") {
    if (values == null || length < 2 || length > 8194) return -1;
    if (values[0] < 0 || values[0] > 4096 || values[1] < 0 || values[1] > 4096) return -1;
    usz text_length = (usz)values[0];
    usz pattern_length = (usz)values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (usz index = 0; index < text_length + pattern_length; index++) {
        if (values[2 + index] < 0 || values[2 + index] > 126) return -1;
    }
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    usz pattern_start = 2 + text_length;
    long last_occurrence[127];
    for (usz byte = 0; byte < 127; byte++) last_occurrence[byte] = -1;
    for (usz index = 0; index < pattern_length; index++)
        last_occurrence[(usz)values[pattern_start + index]] = (long)index;

    usz[4097] good_suffix;
    usz[4097] border_position;
    for (usz index = 0; index <= pattern_length; index++) {
        good_suffix[index] = 0;
        border_position[index] = 0;
    }
    usz i = pattern_length;
    usz j = pattern_length + 1;
    border_position[i] = j;
    while (i > 0) {
        while (j <= pattern_length && values[pattern_start + i - 1] != values[pattern_start + j - 1]) {
            if (good_suffix[j] == 0) good_suffix[j] = j - i;
            j = border_position[j];
        }
        i--;
        j--;
        border_position[i] = j;
    }
    j = border_position[0];
    for (i = 0; i <= pattern_length; i++) {
        if (good_suffix[i] == 0) good_suffix[i] = j;
        if (i == j) j = border_position[j];
    }

    usz alignment = 0;
    while (alignment <= text_length - pattern_length) {
        usz pattern_index = pattern_length;
        while (pattern_index > 0 &&
               values[pattern_start + pattern_index - 1] == values[2 + alignment + pattern_index - 1])
            pattern_index--;
        if (pattern_index == 0) return (long)alignment;
        usz text_byte = (usz)values[2 + alignment + pattern_index - 1];
        long bad_shift = (long)(pattern_index - 1) - last_occurrence[text_byte];
        if (bad_shift < 1) bad_shift = 1;
        usz good_shift = good_suffix[pattern_index];
        alignment += good_shift > (usz)bad_shift ? good_shift : (usz)bad_shift;
    }
    return -1;
}
