module kmp_slp_jump_output;

const usz MAX_PATTERN = 6;
const usz MAX_VARIABLES = 12;
const usz MAX_FACTORS = 8;
const usz MAX_TEXT = 64;
const usz MAX_INPUT = 53;
const usz MAX_OUTPUT_BYTES = 520;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long kmp_slp_jump_output(long* input, usz length, char* output, usz capacity)
        @export("kmp_slp_jump_output") {
    if (input == null || length < 8 || length > MAX_INPUT) return -1;
    usz cursor = 0;
    long pattern_raw = input[cursor]; cursor += 1;
    if (pattern_raw < 1 || pattern_raw > MAX_PATTERN.long()) return -1;
    usz pattern_length = pattern_raw.usz();
    long[MAX_PATTERN] pattern = zeroed;
    for (usz i = 0; i < pattern_length; i += 1) { pattern[i] = input[cursor]; cursor += 1; if (pattern[i] < 0 || pattern[i] > 3) return -1; }
    if (cursor >= length) return -1;
    long variable_raw = input[cursor]; cursor += 1;
    if (variable_raw < 1 || variable_raw > MAX_VARIABLES.long() || cursor + 3 * variable_raw.usz() + 1 > length) return -1;
    usz variable_count = variable_raw.usz();
    int[MAX_VARIABLES] kind = zeroed, first = zeroed, second = zeroed;
    long[MAX_VARIABLES] terminal = zeroed;
    usz[MAX_VARIABLES] variable_length = zeroed;
    for (usz variable = 0; variable < variable_count; variable += 1) {
        long kind_raw = input[cursor], first_raw = input[cursor + 1], second_raw = input[cursor + 2]; cursor += 3;
        if (kind_raw == 0) {
            if (first_raw < 0 || first_raw > 3 || second_raw != 0) return -1;
            terminal[variable] = first_raw;
            variable_length[variable] = 1;
        } else if (kind_raw == 1) {
            if (first_raw < 0 || second_raw < 0 || first_raw >= variable.long() || second_raw >= variable.long()) return -1;
            kind[variable] = 1; first[variable] = first_raw.int(); second[variable] = second_raw.int();
            variable_length[variable] = variable_length[first[variable].usz()] + variable_length[second[variable].usz()];
            if (variable_length[variable] > MAX_TEXT) return -1;
        } else return -1;
    }
    if (cursor >= length) return -1;
    long factor_raw = input[cursor]; cursor += 1;
    if (factor_raw < 1 || factor_raw > MAX_FACTORS.long() || cursor + factor_raw.usz() != length) return -1;
    usz factor_count = factor_raw.usz();
    usz[MAX_FACTORS] factors = zeroed;
    usz text_length = 0;
    for (usz i = 0; i < factor_count; i += 1) {
        long factor = input[cursor]; cursor += 1;
        if (factor < 0 || factor >= variable_raw) return -1;
        factors[i] = factor.usz();
        text_length += variable_length[factors[i]];
        if (text_length > MAX_TEXT) return -1;
    }

    usz[MAX_PATTERN] failure = zeroed;
    usz border = 0;
    for (usz i = 1; i < pattern_length; i += 1) {
        while (border > 0 && pattern[i] != pattern[border]) border = failure[border - 1];
        if (pattern[i] == pattern[border]) border += 1;
        failure[i] = border;
    }
    usz[MAX_VARIABLES][MAX_PATTERN] jump = zeroed;
    ulong[MAX_VARIABLES][MAX_PATTERN] output_mask = zeroed;
    for (usz variable = 0; variable < variable_count; variable += 1) for (usz state = 0; state < pattern_length; state += 1) {
        if (kind[variable] == 0) {
            usz next = state;
            while (next > 0 && pattern[next] != terminal[variable]) next = failure[next - 1];
            if (pattern[next] == terminal[variable]) next += 1;
            if (next == pattern_length) { output_mask[variable][state] = 1; next = failure[pattern_length - 1]; }
            jump[variable][state] = next;
        } else {
            usz left = first[variable].usz(), right = second[variable].usz(), middle = jump[left][state];
            jump[variable][state] = jump[right][middle];
            output_mask[variable][state] = output_mask[left][state] | (output_mask[right][middle] << variable_length[left]);
        }
    }
    usz state = 0, offset = 0;
    ulong end_offsets = 0;
    for (usz i = 0; i < factor_count; i += 1) {
        usz variable = factors[i];
        end_offsets |= output_mask[variable][state] << offset;
        state = jump[variable][state];
        offset += variable_length[variable];
    }
    long[1 + MAX_TEXT] words = zeroed;
    usz occurrences = 0;
    for (usz end = 0; end < text_length; end += 1) if (((end_offsets >> end) & 1) != 0) {
        if (end + 1 < pattern_length) return -1;
        words[1 + occurrences] = (end + 1 - pattern_length).long();
        occurrences += 1;
    }
    words[0] = occurrences.long();
    usz output_bytes = 8 * (1 + occurrences);
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    for (usz word = 0; word < 1 + occurrences; word += 1) store_i64_le(&staged[0], 8 * word, words[word]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return output_bytes.long();
}
