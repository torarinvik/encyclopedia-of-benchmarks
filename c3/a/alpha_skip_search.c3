module alpha_skip_search;

const usz MAX_TEXT = 4096;
const usz MAX_PATTERN = 128;
const usz MAX_INPUT_LENGTH = 4227;
const usz MAX_BUCKETS = 64;

fn long alpha_skip_search(long* input, usz length) @export("alpha_skip_search") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long raw_text_length = input[0];
    long raw_pattern_length = input[1];
    if (raw_text_length < 0 || raw_text_length > (long)MAX_TEXT ||
        raw_pattern_length < 1 || raw_pattern_length > (long)MAX_PATTERN) return -1;
    usz text_length = (usz)raw_text_length;
    usz pattern_length = (usz)raw_pattern_length;
    if (length != 2 + text_length + pattern_length) return -1;

    uchar[MAX_TEXT] text = zeroed;
    uchar[MAX_PATTERN] pattern = zeroed;
    for (usz i = 0; i < text_length; i++) {
        long symbol = input[2 + i];
        if (symbol < 0 || symbol > 3) return -1;
        text[i] = (uchar)symbol;
    }
    for (usz i = 0; i < pattern_length; i++) {
        long symbol = input[2 + text_length + i];
        if (symbol < 0 || symbol > 3) return -1;
        pattern[i] = (uchar)symbol;
    }
    if (text_length < pattern_length) return 0;

    usz factor_length = 1;
    usz bucket_count = 4;
    while (bucket_count * 4 <= pattern_length) {
        factor_length++;
        bucket_count *= 4;
    }
    usz shift = pattern_length - factor_length + 1;
    int power = 1;
    for (usz i = 1; i < factor_length; i++) power *= 4;

    int[MAX_BUCKETS] head = {};
    int[MAX_PATTERN] next_factor = {};
    for (usz code = 0; code < bucket_count; code++) head[code] = -1;
    int factor_code = 0;
    for (usz i = 0; i < factor_length; i++) factor_code = factor_code * 4 + (int)pattern[i];
    for (usz position = 0; position + factor_length <= pattern_length; position++) {
        next_factor[position] = head[factor_code];
        head[factor_code] = (int)position;
        if (position + factor_length < pattern_length)
            factor_code = (factor_code - (int)pattern[position] * power) * 4
                        + (int)pattern[position + factor_length];
    }

    long match_count = 0;
    long offset_sum = 0;
    long offset_xor = 0;
    int text_factor_code = 0;
    for (usz i = 0; i < factor_length; i++) text_factor_code = text_factor_code * 4 + (int)text[i];
    usz last_factor_start = text_length - factor_length;
    for (usz sample_start = 0; sample_start <= last_factor_start; sample_start++) {
        if (sample_start % shift == 0) {
            int position = head[text_factor_code];
            while (position >= 0) {
                long candidate = (long)sample_start - position;
                if (candidate >= 0 && candidate + raw_pattern_length <= raw_text_length) {
                    usz compared = 0;
                    while (compared < pattern_length &&
                           text[(usz)candidate + compared] == pattern[compared]) compared++;
                    if (compared == pattern_length) {
                        match_count++;
                        offset_sum += candidate;
                        offset_xor ^= candidate;
                    }
                }
                position = next_factor[position];
            }
        }
        if (sample_start < last_factor_start)
            text_factor_code = (text_factor_code - (int)text[sample_start] * power) * 4
                             + (int)text[sample_start + factor_length];
    }
    return (match_count << 36) | (offset_sum << 12) | offset_xor;
}
