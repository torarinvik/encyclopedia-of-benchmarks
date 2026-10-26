module parameterized_pattern_matching;

const usz MAX_TEXT = 24;
const usz MAX_PATTERN = 8;
const usz MAX_INPUT = 34;
const usz MAX_OUTPUT_BYTES = 200;
const usz ALPHABET = 16;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn void predecessor_code(long* input, usz offset, usz length, long* code) {
    long[ALPHABET] last = zeroed;
    for (usz symbol = 0; symbol < ALPHABET; symbol += 1) last[symbol] = -1;
    for (usz index = 0; index < length; index += 1) {
        usz symbol = (usz)input[offset + index];
        code[index] = last[symbol] < 0 ? 0 : (long)index - last[symbol];
        last[symbol] = (long)index;
    }
}

long parameterized_pattern_matching(long* input, usz length, char* output,
        usz capacity) @export("parameterized_pattern_matching") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long text_length_value = input[0], pattern_length_value = input[1];
    if (text_length_value < 0 || text_length_value > (long)MAX_TEXT ||
        pattern_length_value < 1 || pattern_length_value > (long)MAX_PATTERN) return -1;
    usz text_length = (usz)text_length_value;
    usz pattern_length = (usz)pattern_length_value;
    if (length != 2 + text_length + pattern_length) return -1;
    for (usz index = 2; index < length; index += 1) {
        if (input[index] < 0 || input[index] >= (long)ALPHABET) return -1;
    }

    long[MAX_PATTERN] pattern_code = zeroed;
    predecessor_code(input, 2 + text_length, pattern_length, &pattern_code[0]);
    usz[MAX_TEXT] matches = zeroed;
    usz match_count = 0;
    if (pattern_length <= text_length) {
        for (usz start = 0; start <= text_length - pattern_length; start += 1) {
            long[MAX_PATTERN] window_code = zeroed;
            predecessor_code(input, 2 + start, pattern_length, &window_code[0]);
            usz index = 0;
            while (index < pattern_length && pattern_code[index] == window_code[index]) index += 1;
            if (index == pattern_length) { matches[match_count] = start; match_count += 1; }
        }
    }

    usz output_bytes = 8 * (match_count + 1);
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    store_i64_le(&staged[0], 0, (long)match_count);
    for (usz index = 0; index < match_count; index += 1) {
        store_i64_le(&staged[0], 8 * (index + 1), (long)matches[index]);
    }
    for (usz index = 0; index < output_bytes; index += 1) output[index] = staged[index];
    return (long)output_bytes;
}
