module horspool_search;

fn long horspool_search(long* packed, usz length) @export("horspool_search")
{
    if (length < 2) return -2;
    long text_length_value = packed[0];
    long pattern_length_value = packed[1];
    if (text_length_value < 0 || text_length_value > 512 || pattern_length_value < 0
        || pattern_length_value > 64 || length != (usz)(text_length_value + pattern_length_value) + 2) return -2;
    usz text_length = (usz)text_length_value;
    usz pattern_length = (usz)pattern_length_value;
    usz pattern_start = 2 + text_length;
    for (usz index = 0; index < text_length; index++) if (packed[2 + index] < 0 || packed[2 + index] > 127) return -2;
    for (usz index = 0; index < pattern_length; index++) if (packed[pattern_start + index] < 0 || packed[pattern_start + index] > 127) return -2;
    if (pattern_length == 0 || pattern_length > text_length) return -1;
    usz[128] shifts;
    for (usz ch = 0; ch < 128; ch++) shifts[ch] = pattern_length;
    for (usz index = pattern_length - 1; index > 0; index--) {
        usz ch = (usz)packed[pattern_start + index - 1];
        if (shifts[ch] == pattern_length) shifts[ch] = pattern_length - index;
    }
    usz end = pattern_length - 1;
    while (end < text_length) {
        usz offset = 0;
        while (offset < pattern_length && packed[pattern_start + pattern_length - 1 - offset] == packed[2 + end - offset]) offset++;
        if (offset == pattern_length) return (long)(end - pattern_length + 1);
        end += shifts[(usz)packed[2 + end]];
    }
    return -1;
}
