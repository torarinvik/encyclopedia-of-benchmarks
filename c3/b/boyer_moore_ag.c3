module boyer_moore_ag;

const MAX_INPUT_VALUES = 512;

fn usz collect_matches(long* values, usz text_length, usz pattern_length,
                       usz pattern_start, char* positions) {
    usz[128] bad_shift;
    bool[128] present;
    usz[256] suffix_skip;
    for (usz byte = 0; byte < 128; byte++) {
        bad_shift[byte] = 0;
        present[byte] = false;
    }
    for (usz shift = 0; shift < 256; shift++) suffix_skip[shift] = 0;
    for (usz index = 0; index + 1 < pattern_length; index++) {
        usz byte = values[pattern_start + index].usz();
        bad_shift[byte] = pattern_length - index - 1;
        present[byte] = true;
    }
    for (usz byte = 0; byte < 128; byte++) {
        if (!present[byte]) continue;
        usz shift = bad_shift[byte];
        usz matched = 0;
        while (matched < pattern_length - shift &&
               values[pattern_start + pattern_length - 1 - matched] ==
                   values[pattern_start + pattern_length - 1 - shift - matched]) matched++;
        suffix_skip[shift] = matched;
    }

    usz count = 0;
    usz start = 0;
    usz jump = pattern_length;
    while (start <= text_length - pattern_length) {
        usz skip = suffix_skip[jump];
        long index = (long)pattern_length - 1;
        while (index >= 0) {
            if (values[2 + start + (usz)index] != values[pattern_start + (usz)index]) {
                usz mismatch = values[2 + start + (usz)index].usz();
                jump = present[mismatch] ? bad_shift[mismatch] : pattern_length;
                start += jump;
                break;
            }
            if ((usz)index == pattern_length - jump) index -= (long)skip;
            if (index == 0) {
                positions[count++] = (char)start;
                jump = 1;
                start++;
                break;
            }
            index--;
        }
    }
    return count;
}

fn long boyer_moore_ag(long* values, usz length, char* output, usz output_capacity)
        @export("boyer_moore_ag") {
    if (values == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 0 || values[0] > 255 || values[1] < 1 || values[1] > 255) return -1;
    usz text_length = values[0].usz();
    usz pattern_length = values[1].usz();
    if (length != 2 + text_length + pattern_length) return -1;
    for (usz index = 0; index < text_length + pattern_length; index++)
        if (values[2 + index] < 0 || values[2 + index] > 127) return -1;

    char[255] positions;
    usz count = pattern_length > text_length ? 0 :
        collect_matches(values, text_length, pattern_length, 2 + text_length, &positions[0]);
    if (output_capacity < count || (count != 0 && output == null)) return -2;
    for (usz index = 0; index < count; index++) output[index] = positions[index];
    return (long)count;
}
