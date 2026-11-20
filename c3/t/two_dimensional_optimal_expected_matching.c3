module two_dimensional_optimal_expected_matching;

const usz MAX_SIDE = 12;
const usz MAX_CELLS = MAX_SIDE * MAX_SIDE;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_CELLS;
const usz MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1;

fn usz sample_code(long* input, usz base, usz side, usz row, usz column,
                   usz count, usz stride) {
    usz code = 0;
    for (usz offset = 0; offset < count; offset += 1) {
        usz at = base + row * side + column + offset * stride;
        code = 4 * code + (usz)input[at];
    }
    return code;
}

fn void put_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (uint8)(bits & 255);
        bits >>= 8;
    }
}

fn long two_dimensional_optimal_expected_matching(
        long* input, usz length, uint8* output, usz capacity)
        @export("two_dimensional_optimal_expected_matching") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long n_value = input[0];
    long m_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_SIDE || m_value < 1 || m_value > n_value) return -1;

    usz n = (usz)n_value;
    usz m = (usz)m_value;
    usz text_size = n * n;
    usz pattern_size = m * m;
    if (length != 2 + text_size + pattern_size) return -1;
    usz pattern_base = 2 + text_size;
    for (usz index = 0; index < text_size + pattern_size; index += 1) {
        if (input[2 + index] < 0 || input[2 + index] > 3) return -1;
    }

    usz q = 1;
    usz code_capacity = 4;
    while (code_capacity < pattern_size) {
        q += 1;
        code_capacity *= 4;
    }
    usz stride = m / q;
    usz final_offset = (q - 1) * stride;
    short[256] heads = zeroed;
    short[MAX_CELLS] next = zeroed;
    uint8[MAX_CELLS] address_row = zeroed;
    uint8[MAX_CELLS] address_column = zeroed;
    for (usz code = 0; code < 256; code += 1) heads[code] = -1;

    usz address_count = 0;
    for (usz row = 0; row < m; row += 1) {
        for (usz residue = 0; residue < stride; residue += 1) {
            usz code = sample_code(input, pattern_base, m, row, residue, q, stride);
            address_row[address_count] = (uint8)row;
            address_column[address_count] = (uint8)residue;
            next[address_count] = heads[code];
            heads[code] = (short)address_count;
            address_count += 1;
        }
    }

    bool[MAX_CELLS] tested = zeroed;
    bool[MAX_CELLS] matched = zeroed;
    usz row_starts = n - m + 1;
    usz column_starts = n - m + 1;
    for (usz text_row = 0; text_row < n; text_row += m) {
        for (usz text_column = 0; text_column + final_offset < n; text_column += stride) {
            usz code = sample_code(input, 2, n, text_row, text_column, q, stride);
            short address = heads[code];
            while (address >= 0) {
                usz slot = (usz)address;
                long candidate_row = (long)text_row - (long)address_row[slot];
                long candidate_column = (long)text_column - (long)address_column[slot];
                if (candidate_row >= 0 && candidate_column >= 0 &&
                        (usz)candidate_row < row_starts && (usz)candidate_column < column_starts) {
                    usz candidate = (usz)candidate_row * n + (usz)candidate_column;
                    if (!tested[candidate]) {
                        tested[candidate] = true;
                        bool equal = true;
                        for (usz row = 0; row < m && equal; row += 1) {
                            for (usz column = 0; column < m; column += 1) {
                                usz text_at = 2 + ((usz)candidate_row + row) * n + (usz)candidate_column + column;
                                usz pattern_at = pattern_base + row * m + column;
                                if (input[text_at] != input[pattern_at]) { equal = false; break; }
                            }
                        }
                        matched[candidate] = equal;
                    }
                }
                address = next[slot];
            }
        }
    }

    usz match_count = 0;
    for (usz row = 0; row < row_starts; row += 1)
        for (usz column = 0; column < column_starts; column += 1)
            if (matched[row * n + column]) match_count += 1;

    usz output_bytes = 8 * (1 + 2 * match_count);
    if (output == null || capacity < output_bytes) return -2;
    put_i64_le(output, 0, (long)match_count);
    usz output_word = 1;
    for (usz row = 0; row < row_starts; row += 1) {
        for (usz column = 0; column < column_starts; column += 1) {
            if (!matched[row * n + column]) continue;
            put_i64_le(output, 8 * output_word++, (long)row);
            put_i64_le(output, 8 * output_word++, (long)column);
        }
    }
    return (long)output_bytes;
}
