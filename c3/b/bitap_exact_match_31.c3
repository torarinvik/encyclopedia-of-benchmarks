module bitap_exact_match_31;

const usz MAX_TEXT_LENGTH = 4096;
const usz MAX_PATTERN_LENGTH = 31;

fn long bitap_exact_match_31(long* values, usz length) @export("bitap_exact_match_31") {
    if (values == null || length < 2 || values[0] < 0 || values[0] > (long)MAX_TEXT_LENGTH || values[1] < 0 || values[1] > (long)MAX_PATTERN_LENGTH) return -2;
    usz text_length = (usz)values[0], pattern_length = (usz)values[1];
    if (length != 2 + text_length + pattern_length) return -2;
    for (usz i = 2; i < length; i++) if (values[i] < 'a' || values[i] > 'z') return -2;
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;
    uint[26] masks;
    for (usz c = 0; c < 26; c++) masks[c] = ~(uint)0;
    for (usz i = 0; i < pattern_length; i++) masks[(usz)(values[2 + text_length + i] - 'a')] &= ~((uint)1 << i);
    uint state = ~((uint)1);
    for (usz i = 0; i < text_length; i++) {
        state |= masks[(usz)(values[2 + i] - 'a')];
        state <<= 1;
        if ((state & ((uint)1 << pattern_length)) == 0) return (long)i - (long)pattern_length + 1;
    }
    return -1;
}
