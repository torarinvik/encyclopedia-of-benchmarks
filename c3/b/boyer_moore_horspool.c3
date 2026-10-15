module boyer_moore_horspool;

const MAX_INPUT_VALUES = 512;

fn usz count_matches(long* values, usz text_length, usz pattern_length,
                     usz pattern_start, usz* shifts) {
    if (pattern_length == 0) return text_length + 1;
    if (pattern_length > text_length) return 0;
    usz count = 0;
    usz start = 0;
    while (start <= text_length - pattern_length) {
        usz current = pattern_length;
        while (current > 0 && values[pattern_start + current - 1] == values[2 + start + current - 1]) current--;
        if (current == 0) {
            count++;
            start++;
        } else {
            usz tail = values[2 + start + pattern_length - 1].usz();
            start += shifts[tail];
        }
    }
    return count;
}

fn long boyer_moore_horspool(long* values, usz length, char* output, usz output_capacity)
        @export("boyer_moore_horspool") {
    if (values == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 0 || values[0] > 255 || values[1] < 0 || values[1] > 255) return -1;
    usz text_length = values[0].usz();
    usz pattern_length = values[1].usz();
    if (length != 2 + text_length + pattern_length) return -1;
    usz pattern_start = 2 + text_length;
    for (usz index = 0; index < text_length + pattern_length; index++)
        if (values[2 + index] < 0 || values[2 + index] > 127) return -1;

    usz[128] shifts;
    for (usz byte = 0; byte < 128; byte++) shifts[byte] = pattern_length;
    for (usz index = 0; index + 1 < pattern_length; index++)
        shifts[values[pattern_start + index].usz()] = pattern_length - 1 - index;
    usz match_count = count_matches(values, text_length, pattern_length, pattern_start, &shifts[0]);
    if (output_capacity < match_count || (match_count != 0 && output == null)) return -2;

    usz written = 0;
    if (pattern_length == 0) {
        for (usz position = 0; position <= text_length; position++) output[written++] = (char)position;
    } else if (pattern_length <= text_length) {
        usz start = 0;
        while (start <= text_length - pattern_length) {
            usz current = pattern_length;
            while (current > 0 && values[pattern_start + current - 1] == values[2 + start + current - 1]) current--;
            if (current == 0) {
                output[written++] = (char)start;
                start++;
            } else {
                usz tail = values[2 + start + pattern_length - 1].usz();
                start += shifts[tail];
            }
        }
    }
    return (long)written;
}
