module agrep_approx_substring_count;

const usz MAX_PATTERN_LENGTH = 63;
const usz MAX_TEXT_LENGTH = 4096;
const usz MAX_ERRORS = 2;

fn long agrep_approx_substring_count(long* values, usz length) @export("agrep_approx_substring_count") {
    if (values == null || length < 3 || values[0] < 1 || values[0] > (long)MAX_PATTERN_LENGTH ||
        values[1] < 0 || values[1] > (long)MAX_TEXT_LENGTH || values[2] < 0 || values[2] > (long)MAX_ERRORS)
        return -2;
    usz pattern_length = (usz)values[0];
    usz text_length = (usz)values[1];
    if (length != 3 + pattern_length + text_length) return -2;
    for (usz i = 3; i < length; i++) {
        if (values[i] < 32 || values[i] > 126) return -2;
    }

    long[64] previous;
    long[64] current;
    for (usz j = 0; j <= pattern_length; j++) previous[j] = (long)j;
    long matches = 0;
    usz text_offset = 3 + pattern_length;
    for (usz i = 0; i < text_length; i++) {
        current[0] = 0;
        for (usz j = 1; j <= pattern_length; j++) {
            long substitution = previous[j - 1] + (values[3 + j - 1] == values[text_offset + i] ? 0 : 1);
            long best = previous[j] + 1;
            if (current[j - 1] + 1 < best) best = current[j - 1] + 1;
            if (substitution < best) best = substitution;
            current[j] = best;
        }
        if (current[pattern_length] <= values[2]) matches++;
        for (usz j = 0; j <= pattern_length; j++) previous[j] = current[j];
    }
    return matches;
}
