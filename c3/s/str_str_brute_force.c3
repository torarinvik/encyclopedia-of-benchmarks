module str_str_brute_force;

const MAX_LENGTH = 2050;
const MAX_STRING_LENGTH = 1024;

// Return the first pattern occurrence using a direct character-by-character scan.
fn long str_str_brute_force(long* packed, usz length) @export("str_str_brute_force") {
    if (packed == null || length < 2 || length > MAX_LENGTH) { return -1; }
    if (packed[0] < 0 || packed[0] > MAX_STRING_LENGTH ||
        packed[1] < 0 || packed[1] > MAX_STRING_LENGTH) { return -1; }
    usz text_length = (usz)packed[0];
    usz pattern_length = (usz)packed[1];
    if (length != 2 + text_length + pattern_length) { return -1; }
    for (usz index = 0; index < text_length + pattern_length; index++) {
        if (packed[2 + index] < 1 || packed[2 + index] > 127) { return -1; }
    }
    if (pattern_length == 0) { return 0; }
    if (pattern_length > text_length) { return -1; }

    usz pattern_start = 2 + text_length;
    for (usz start = 0; start <= text_length - pattern_length; start++) {
        usz offset = 0;
        while (offset < pattern_length &&
               packed[2 + start + offset] == packed[pattern_start + offset]) { offset++; }
        if (offset == pattern_length) { return (long)start; }
    }
    return -1;
}
