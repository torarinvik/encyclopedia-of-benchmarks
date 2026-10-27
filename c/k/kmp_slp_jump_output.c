#include <stddef.h>
#include <stdint.h>

enum { MAX_PATTERN = 6, MAX_VARIABLES = 12, MAX_FACTORS = 8, MAX_TEXT = 64,
       MAX_INPUT = 53, MAX_OUTPUT_BYTES = 520 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t kmp_slp_jump_output(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 8 || length > MAX_INPUT) return -1;
    size_t cursor = 0;
    const int64_t pattern_raw = input[cursor++];
    if (pattern_raw < 1 || pattern_raw > MAX_PATTERN) return -1;
    const size_t pattern_length = (size_t)pattern_raw;
    int64_t pattern[MAX_PATTERN] = {0};
    for (size_t i = 0; i < pattern_length; ++i) {
        pattern[i] = input[cursor++];
        if (pattern[i] < 0 || pattern[i] > 3) return -1;
    }
    if (cursor >= length) return -1;
    const int64_t variable_raw = input[cursor++];
    if (variable_raw < 1 || variable_raw > MAX_VARIABLES || cursor + 3u * (size_t)variable_raw + 1 > length) return -1;
    const size_t variable_count = (size_t)variable_raw;
    int kind[MAX_VARIABLES] = {0}, first[MAX_VARIABLES] = {0}, second[MAX_VARIABLES] = {0};
    size_t variable_length[MAX_VARIABLES] = {0};
    uint8_t terminal[MAX_VARIABLES] = {0};
    for (size_t variable = 0; variable < variable_count; ++variable) {
        const int64_t kind_raw = input[cursor++], first_raw = input[cursor++], second_raw = input[cursor++];
        if (kind_raw == 0) {
            if (first_raw < 0 || first_raw > 3 || second_raw != 0) return -1;
            kind[variable] = 0;
            terminal[variable] = (uint8_t)first_raw;
            variable_length[variable] = 1;
        } else if (kind_raw == 1) {
            if (first_raw < 0 || second_raw < 0 || first_raw >= (int64_t)variable || second_raw >= (int64_t)variable) return -1;
            kind[variable] = 1;
            first[variable] = (int)first_raw;
            second[variable] = (int)second_raw;
            variable_length[variable] = variable_length[first[variable]] + variable_length[second[variable]];
            if (variable_length[variable] > MAX_TEXT) return -1;
        } else return -1;
    }
    if (cursor >= length) return -1;
    const int64_t factor_raw = input[cursor++];
    if (factor_raw < 1 || factor_raw > MAX_FACTORS || cursor + (size_t)factor_raw != length) return -1;
    const size_t factor_count = (size_t)factor_raw;
    size_t factors[MAX_FACTORS], text_length = 0;
    for (size_t i = 0; i < factor_count; ++i) {
        const int64_t factor = input[cursor++];
        if (factor < 0 || factor >= variable_raw) return -1;
        factors[i] = (size_t)factor;
        text_length += variable_length[factors[i]];
        if (text_length > MAX_TEXT) return -1;
    }

    size_t failure[MAX_PATTERN] = {0};
    size_t border = 0;
    for (size_t i = 1; i < pattern_length; ++i) {
        while (border > 0 && pattern[i] != pattern[border]) border = failure[border - 1];
        if (pattern[i] == pattern[border]) ++border;
        failure[i] = border;
    }
    uint8_t jump[MAX_VARIABLES][MAX_PATTERN] = {{0}};
    uint64_t output_mask[MAX_VARIABLES][MAX_PATTERN] = {{0}};
    for (size_t variable = 0; variable < variable_count; ++variable) {
        for (size_t state = 0; state < pattern_length; ++state) {
            if (kind[variable] == 0) {
                size_t next = state;
                while (next > 0 && pattern[next] != terminal[variable]) next = failure[next - 1];
                if (pattern[next] == terminal[variable]) ++next;
                if (next == pattern_length) {
                    output_mask[variable][state] = UINT64_C(1); /* end offset 0 in this terminal */
                    next = failure[pattern_length - 1]; /* preserve overlapping matches */
                }
                jump[variable][state] = (uint8_t)next;
            } else {
                const size_t left = (size_t)first[variable], right = (size_t)second[variable];
                const size_t middle = jump[left][state];
                jump[variable][state] = jump[right][middle];
                output_mask[variable][state] = output_mask[left][state]
                    | (output_mask[right][middle] << variable_length[left]);
            }
        }
    }

    size_t state = 0, offset = 0;
    uint64_t end_offsets = 0;
    for (size_t i = 0; i < factor_count; ++i) {
        const size_t variable = factors[i];
        end_offsets |= output_mask[variable][state] << offset;
        state = jump[variable][state];
        offset += variable_length[variable];
    }
    int64_t words[1 + MAX_TEXT] = {0};
    size_t occurrence_count = 0;
    for (size_t end = 0; end < text_length; ++end) {
        if (((end_offsets >> end) & 1u) != 0) {
            if (end + 1 < pattern_length) return -1;
            words[1 + occurrence_count++] = (int64_t)(end + 1 - pattern_length);
        }
    }
    words[0] = (int64_t)occurrence_count;
    const size_t output_bytes = 8 * (1 + occurrence_count);
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (size_t word = 0; word < 1 + occurrence_count; ++word) store_i64_le(staged, 8 * word, words[word]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
