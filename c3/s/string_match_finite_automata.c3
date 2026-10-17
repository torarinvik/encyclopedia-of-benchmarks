module string_match_finite_automata;

const usz MAX_TEXT_LENGTH = 256;
const usz MAX_PATTERN_LENGTH = 32;
const usz ALPHABET_SIZE = 128;
const usz TRANSITION_TABLE_SIZE = (MAX_PATTERN_LENGTH + 1) * ALPHABET_SIZE;
const usz MAX_PARSEABLE_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH + 1;

fn usz next_state(long* pattern, usz pattern_length, usz state, long symbol) {
    if (state < pattern_length && symbol == pattern[state]) return state + 1;
    for (usz candidate = state; candidate > 0; candidate -= 1) {
        if (pattern[candidate - 1] != symbol) continue;
        bool prefix_matches = true;
        for (usz i = 0; i + 1 < candidate; i += 1) {
            if (pattern[i] != pattern[state - candidate + i + 1]) {
                prefix_matches = false;
                break;
            }
        }
        if (prefix_matches) return candidate;
    }
    return 0;
}

fn void store_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long string_match_finite_automata(long* values, usz length, char* output, usz output_capacity)
    @export("string_match_finite_automata") {
    if (values == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long raw_text_length = values[0];
    long raw_pattern_length = values[1];
    if (raw_text_length < 0 || raw_text_length > (long)MAX_TEXT_LENGTH ||
        raw_pattern_length < 1 || raw_pattern_length > (long)MAX_PATTERN_LENGTH ||
        length != 2 + (usz)raw_text_length + (usz)raw_pattern_length) return -1;
    usz text_length = (usz)raw_text_length;
    usz pattern_length = (usz)raw_pattern_length;
    for (usz i = 0; i < text_length + pattern_length; i += 1)
        if (values[2 + i] < 0 || values[2 + i] >= (long)ALPHABET_SIZE) return -1;

    long* text = values + 2;
    long* pattern = text + text_length;
    int[TRANSITION_TABLE_SIZE] transitions;
    for (usz state = 0; state <= pattern_length; state += 1)
        for (usz symbol = 0; symbol < ALPHABET_SIZE; symbol += 1)
            transitions[state * ALPHABET_SIZE + symbol] =
                (int)next_state(pattern, pattern_length, state, (long)symbol);

    int[MAX_TEXT_LENGTH] matches;
    usz match_count = 0;
    usz state = 0;
    for (usz index = 0; index < text_length; index += 1) {
        state = (usz)transitions[state * ALPHABET_SIZE + (usz)text[index]];
        if (state == pattern_length) {
            matches[match_count] = (int)(index + 1 - pattern_length);
            match_count += 1;
        }
    }

    usz byte_count = 4 * match_count;
    if (output == null || output_capacity < byte_count) return -2;
    for (usz index = 0; index < match_count; index += 1)
        store_i32_le(output, 4 * index, matches[index]);
    return (long)byte_count;
}
