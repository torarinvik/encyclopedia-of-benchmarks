module kmp_all_occurrences;

const usz MAX_TEXT_LENGTH = 256;
const usz MAX_PATTERN_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 322;

fn long kmp_all_occurrences(long* values, usz length, char* output, usz output_capacity)
    @export("kmp_all_occurrences") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long text_length_value = values[0];
    long pattern_length_value = values[1];
    if (text_length_value < 0 || text_length_value > (long)MAX_TEXT_LENGTH ||
        pattern_length_value < 1 || pattern_length_value > (long)MAX_PATTERN_LENGTH) return -1;
    usz text_length = (usz)text_length_value;
    usz pattern_length = (usz)pattern_length_value;
    if (length != 2 + text_length + pattern_length) return -1;
    usz pattern_offset = 2 + text_length;
    for (usz i = 0; i < text_length + pattern_length; i += 1)
        if (values[2 + i] < 0 || values[2 + i] > 127) return -1;

    usz[MAX_PATTERN_LENGTH] prefix = {};
    for (usz i = 1; i < pattern_length; i += 1) {
        usz matched = prefix[i - 1];
        while (matched > 0 && values[pattern_offset + i] != values[pattern_offset + matched])
            matched = prefix[matched - 1];
        if (values[pattern_offset + i] == values[pattern_offset + matched]) matched += 1;
        prefix[i] = matched;
    }

    usz[MAX_TEXT_LENGTH] matches;
    usz match_count = 0;
    usz matched = 0;
    for (usz i = 0; i < text_length; i += 1) {
        while (matched > 0 && values[2 + i] != values[pattern_offset + matched])
            matched = prefix[matched - 1];
        if (values[2 + i] == values[pattern_offset + matched]) matched += 1;
        if (matched == pattern_length) {
            matches[match_count] = i + 1 - pattern_length;
            match_count += 1;
            matched = prefix[matched - 1];
        }
    }

    usz output_bytes = match_count * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz i = 0; i < match_count; i += 1) {
        ulong bits = (ulong)matches[i];
        for (usz byte = 0; byte < 8; byte += 1)
            output[i * 8 + byte] = (char)((bits >> (byte * 8)) & 255);
    }
    return (long)output_bytes;
}
