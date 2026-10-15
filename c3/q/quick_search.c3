module quick_search;

fn long quick_search(long* values, usz length) @export("quick_search") {
    if (values == null || length < 2 || length > 512) return -1;
    if (values[0] < 0 || values[0] > 255 || values[1] < 0 || values[1] > 255) return -1;
    usz text_length = (usz)values[0];
    usz pattern_length = (usz)values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (usz index = 0; index < text_length + pattern_length; index++) {
        if (values[2 + index] < 0 || values[2 + index] > 127) return -1;
    }
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    usz[128] shift;
    for (usz byte = 0; byte < 128; byte++) shift[byte] = pattern_length;
    usz pattern_start = 2 + text_length;
    for (usz index = 0; index < pattern_length; index++) {
        shift[(usz)values[pattern_start + index]] = pattern_length - index;
    }

    usz position = 0;
    while (position <= text_length - pattern_length) {
        usz index = pattern_length;
        while (index > 0 && values[2 + position + index - 1] == values[pattern_start + index - 1]) index--;
        if (index == 0) return (long)position;
        if (position + pattern_length >= text_length) break;
        position += shift[(usz)values[2 + position + pattern_length]];
    }
    return -1;
}
