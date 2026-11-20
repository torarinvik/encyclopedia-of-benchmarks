module parameterized_pattern_matching_kmp;

const usz MAX_TEXT = 64;
const usz MAX_PATTERN = 16;
const usz MAX_ALPHABET = 16;
const usz MAX_PARSEABLE_INPUT = 84;
const usz MAX_OUTPUT_BYTES = 520;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn bool pattern_compare(long* pattern, long* previous, long* previous_at,
        usz current, usz prefix_pos) {
    long prior = previous[current];
    if (prior < 0 || (long)current - prior > (long)prefix_pos) {
        return previous_at[prefix_pos] < 0;
    }
    usz distance = current - (usz)prior;
    return pattern[prefix_pos] == pattern[prefix_pos - distance];
}

fn bool text_compare(long* text, usz text_pos, usz pattern_pos,
        long* previous, long* last_text) {
    long prior = previous[pattern_pos];
    usz symbol = (usz)text[text_pos];
    if (prior < 0) return last_text[symbol] < (long)(text_pos - pattern_pos);
    usz distance = pattern_pos - (usz)prior;
    return text[text_pos] == text[text_pos - distance];
}

fn long parameterized_pattern_matching_kmp(long* input, usz length,
        char* output, usz capacity) @export("parameterized_pattern_matching_kmp") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT) return -1;
    long n_value = input[0], m_value = input[1], alphabet_value = input[2];
    if (n_value < 0 || n_value > (long)MAX_TEXT || m_value < 1 ||
        m_value > (long)MAX_PATTERN || alphabet_value < 1 ||
        alphabet_value > (long)MAX_ALPHABET) return -1;
    usz n = (usz)n_value, m = (usz)m_value, alphabet_size = (usz)alphabet_value;
    if (length != 3 + n + m) return -1;
    for (usz index = 3; index < length; index += 1) {
        if (input[index] < 0 || (ulong)input[index] >= alphabet_size) return -1;
    }
    long* text = input + 3;
    long* pattern = text + n;
    long[MAX_PATTERN] previous = zeroed;
    long[MAX_PATTERN] previous_at = zeroed;
    long[MAX_ALPHABET] last_pattern = zeroed;
    long[MAX_PATTERN] failure = zeroed;
    for (usz symbol = 0; symbol < MAX_ALPHABET; symbol += 1) last_pattern[symbol] = -1;
    for (usz index = 0; index < m; index += 1) {
        usz symbol = (usz)pattern[index];
        previous[index] = last_pattern[symbol];
        previous_at[index] = previous[index];
        last_pattern[symbol] = (long)index;
    }
    for (usz current = 1; current < m; current += 1) {
        usz matched = (usz)failure[current - 1];
        while (matched > 0 && !pattern_compare(&pattern[0], &previous[0],
                &previous_at[0], current, matched)) {
            matched = (usz)failure[matched - 1];
        }
        if (pattern_compare(&pattern[0], &previous[0], &previous_at[0], current, matched)) matched += 1;
        failure[current] = (long)matched;
    }
    long[MAX_ALPHABET] last_text = zeroed;
    for (usz symbol = 0; symbol < MAX_ALPHABET; symbol += 1) last_text[symbol] = -1;
    long[MAX_TEXT] matches = zeroed;
    usz match_count = 0, matched = 0;
    if (m <= n) {
        for (usz text_pos = 0; text_pos < n; text_pos += 1) {
            while (true) {
                if (text_compare(&text[0], text_pos, matched,
                        &previous[0], &last_text[0])) {
                    matched += 1;
                    if (matched == m) {
                        matches[match_count] = (long)(text_pos + 1 - m);
                        match_count += 1;
                        matched = (usz)failure[m - 1];
                    }
                    break;
                }
                if (matched == 0) break;
                matched = (usz)failure[matched - 1];
            }
            last_text[(usz)text[text_pos]] = (long)text_pos;
        }
    }
    usz output_bytes = 8 * (match_count + 1);
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    store_i64_le(&staged[0], 0, (long)match_count);
    for (usz index = 0; index < match_count; index += 1) {
        store_i64_le(&staged[0], 8 * (index + 1), matches[index]);
    }
    for (usz index = 0; index < output_bytes; index += 1) output[index] = staged[index];
    return (long)output_bytes;
}
