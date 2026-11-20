#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum {
    KM_MAX_SIDE = 12,
    KM_MAX_CELLS = KM_MAX_SIDE * KM_MAX_SIDE,
    KM_MAX_PARSEABLE_INPUT_LENGTH = 2 + 2 * KM_MAX_CELLS + 1
};

static uint16_t sample_code(const int64_t *input, size_t base, size_t side,
                            size_t row, size_t column, size_t count,
                            size_t stride) {
    uint16_t code = 0;
    for (size_t step = 0; step < count; ++step) {
        const size_t at = base + row * side + column + step * stride;
        code = (uint16_t)(4 * code + (uint16_t)input[at]);
    }
    return code;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t two_dimensional_k_mismatch_linear_templates(
        const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > KM_MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    if (n_value < 3 || n_value > KM_MAX_SIDE || m_value < 3 || m_value > n_value)
        return -1;
    const size_t n = (size_t)n_value;
    const size_t m = (size_t)m_value;
    const size_t text_size = n * n;
    const size_t pattern_size = m * m;
    if (length != 2 + text_size + pattern_size) return -1;
    const size_t pattern_base = 2 + text_size;
    for (size_t index = 0; index < text_size + pattern_size; ++index)
        if (input[2 + index] < 0 || input[2 + index] > 3) return -1;

    size_t q = 1;
    size_t code_capacity = 4;
    while (code_capacity < pattern_size) {
        ++q;
        code_capacity *= 4;
    }
    const size_t stride = m / q;
    const size_t final_offset = (q - 1) * stride;
    int16_t heads[256];
    int16_t next[KM_MAX_CELLS];
    uint8_t sample_row[KM_MAX_CELLS];
    uint8_t sample_column[KM_MAX_CELLS];
    for (size_t code = 0; code < 256; ++code) heads[code] = -1;

    size_t sample_count = 0;
    for (size_t row = 0; row < m; ++row) {
        for (size_t residue = 0; residue < stride; ++residue) {
            const uint16_t code = sample_code(input, pattern_base, m, row,
                                              residue, q, stride);
            sample_row[sample_count] = (uint8_t)row;
            sample_column[sample_count] = (uint8_t)residue;
            next[sample_count] = heads[code];
            heads[code] = (int16_t)sample_count;
            ++sample_count;
        }
    }

    bool considered[KM_MAX_CELLS] = {false};
    bool matched[KM_MAX_CELLS] = {false};
    const size_t starts = n - m + 1;
    for (size_t text_row = 0; text_row < n; ++text_row) {
        if (text_row % m < m - 2) continue;
        for (size_t text_column = 0;
             text_column + final_offset < n;
             text_column += stride) {
            const uint16_t code = sample_code(input, 2, n, text_row,
                                              text_column, q, stride);
            int16_t address = heads[code];
            while (address >= 0) {
                const size_t slot = (size_t)address;
                const int candidate_row = (int)text_row - (int)sample_row[slot];
                const int candidate_column = (int)text_column - (int)sample_column[slot];
                if (candidate_row >= 0 && candidate_column >= 0 &&
                    (size_t)candidate_row < starts &&
                    (size_t)candidate_column < starts) {
                    const size_t candidate = (size_t)candidate_row * n +
                                             (size_t)candidate_column;
                    if (!considered[candidate]) {
                        considered[candidate] = true;
                        size_t mismatches = 0;
                        for (size_t row = 0; row < m && mismatches < 2; ++row) {
                            for (size_t column = 0; column < m; ++column) {
                                const size_t text_at = 2 +
                                    ((size_t)candidate_row + row) * n +
                                    (size_t)candidate_column + column;
                                const size_t pattern_at = pattern_base + row * m + column;
                                if (input[text_at] != input[pattern_at] && ++mismatches == 2)
                                    break;
                            }
                        }
                        matched[candidate] = mismatches <= 1;
                    }
                }
                address = next[slot];
            }
        }
    }

    size_t match_count = 0;
    for (size_t row = 0; row < starts; ++row)
        for (size_t column = 0; column < starts; ++column)
            if (matched[row * n + column]) ++match_count;
    const size_t output_bytes = 8 * (1 + 2 * match_count);
    if (output == NULL || capacity < output_bytes) return -2;
    put_i64_le(output, 0, (int64_t)match_count);
    size_t word = 1;
    for (size_t row = 0; row < starts; ++row) {
        for (size_t column = 0; column < starts; ++column) {
            if (!matched[row * n + column]) continue;
            put_i64_le(output, 8 * word++, (int64_t)row);
            put_i64_le(output, 8 * word++, (int64_t)column);
        }
    }
    return (int64_t)output_bytes;
}
