module bitap_string_match;

const usz MAX_TEXT_LENGTH = 4096;
const usz MAX_PATTERN_LENGTH = 63;

fn long bitap_string_match(long* values, usz length) @export("bitap_string_match") {
    if (values == null || length < 2 || values[0] < 0 || values[0] > (long)MAX_TEXT_LENGTH ||
        values[1] < 0 || values[1] > (long)MAX_PATTERN_LENGTH) return -2;
    usz text_length = (usz)values[0];
    usz pattern_length = (usz)values[1];
    if (length != 2 + text_length + pattern_length) return -2;
    for (usz index = 2; index < length; index++) {
        if (values[index] < 'a' || values[index] > 'z') return -2;
    }
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    ulong[26] masks;
    for (usz letter = 0; letter < 26; letter++) masks[letter] = ~(ulong)0;
    for (usz index = 0; index < pattern_length; index++) {
        usz letter = (usz)(values[2 + text_length + index] - 'a');
        masks[letter] &= ~((ulong)1 << index);
    }
    ulong state = ~((ulong)1);
    for (usz index = 0; index < text_length; index++) {
        usz letter = (usz)(values[2 + index] - 'a');
        state |= masks[letter];
        state <<= 1;
        if ((state & ((ulong)1 << pattern_length)) == 0) {
            return (long)index - (long)pattern_length + 1;
        }
    }
    return -1;
}
