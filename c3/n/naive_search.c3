module naive_search;

const MAX_INPUT_VALUES = 512;

fn long naive_search(long* values, usz length, char* output, usz output_capacity)
        @export("naive_search") {
    if (values == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 0 || values[0] > 255 || values[1] < 0 || values[1] > 255) return -1;
    usz text_length = values[0].usz();
    usz pattern_length = values[1].usz();
    if (length != 2 + text_length + pattern_length) return -1;
    usz pattern_start = 2 + text_length;
    for (usz index = 0; index < text_length; index++)
        if (values[2 + index] < 1 || values[2 + index] > 127) return -1;
    for (usz index = 0; index < pattern_length; index++)
        if (values[pattern_start + index] < 1 || values[pattern_start + index] > 127) return -1;

    usz match_count = 0;
    if (pattern_length <= text_length) {
        for (usz start = 0; start <= text_length - pattern_length; start++) {
            usz offset = 0;
            while (offset < pattern_length && values[2 + start + offset] == values[pattern_start + offset]) offset++;
            if (offset == pattern_length) match_count++;
        }
    }
    if (output_capacity < match_count || (match_count != 0 && output == null)) return -2;
    usz written = 0;
    if (pattern_length <= text_length) {
        for (usz start = 0; start <= text_length - pattern_length; start++) {
            usz offset = 0;
            while (offset < pattern_length && values[2 + start + offset] == values[pattern_start + offset]) offset++;
            if (offset == pattern_length) output[written++] = (char)start;
        }
    }
    return (long)written;
}
