module smith_waterman_python;

const usz MAX_SEQUENCE_LENGTH = 16;
const usz MAX_PARSEABLE_INPUT_LENGTH = 38;
const usz MAX_OUTPUT_BYTES = 1233;
const usz SCORE_STRIDE = 17;
const usz MAX_TRACE_STEPS = 2 * MAX_SEQUENCE_LENGTH;
const usz MAX_ALIGNMENT_BYTES = 2 * MAX_TRACE_STEPS + 1;

fn bool is_ascii_letter_or_gap(long value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') || value == '-';
}

fn long uppercase_ascii(long value) {
    if (value >= 'a' && value <= 'z') value -= 'a' - 'A';
    return value;
}

fn long pair_score(long left, long right, long match_score, long mismatch_score, long gap_score) {
    if (left == '-' || right == '-') return gap_score;
    return left == right ? match_score : mismatch_score;
}

fn void write_u32_le(char* output, usz offset, long value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn void write_i32_le(char* output, usz offset, long value) {
    write_u32_le(output, offset, value);
}

fn long smith_waterman_python(long* input, usz input_length, char* output, usz output_capacity)
    @export("smith_waterman_python") {
    if (input == null || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    long query_length_value = input[0];
    long subject_length_value = input[1];
    long match_score = input[2];
    long mismatch_score = input[3];
    long gap_score = input[4];
    if (query_length_value < 0 || query_length_value > (long)MAX_SEQUENCE_LENGTH ||
        subject_length_value < 0 || subject_length_value > (long)MAX_SEQUENCE_LENGTH ||
        match_score < 1 || match_score > 5 || mismatch_score < -5 || mismatch_score > -1 ||
        gap_score < -5 || gap_score > -1) return -1L;
    usz query_length = (usz)query_length_value;
    usz subject_length = (usz)subject_length_value;
    if (input_length != 5 + query_length + subject_length || input_length > 37) return -1L;
    for (usz i = 5; i < input_length; i++) if (!is_ascii_letter_or_gap(input[i])) return -1L;

    long[MAX_SEQUENCE_LENGTH] query = zeroed;
    long[MAX_SEQUENCE_LENGTH] subject = zeroed;
    for (usz i = 0; i < query_length; i++) query[i] = uppercase_ascii(input[5 + i]);
    for (usz i = 0; i < subject_length; i++) subject[i] = uppercase_ascii(input[5 + query_length + i]);
    usz rows = query_length + 1;
    usz columns = subject_length + 1;
    long[SCORE_STRIDE * SCORE_STRIDE] scores = zeroed;
    long maximum = 0;
    usz max_row = 0, max_column = 0;
    for (usz row = 1; row < rows; row++) {
        for (usz column = 1; column < columns; column++) {
            long diagonal = scores[(row - 1) * SCORE_STRIDE + column - 1] +
                pair_score(query[row - 1], subject[column - 1], match_score, mismatch_score, gap_score);
            long above = scores[(row - 1) * SCORE_STRIDE + column] + gap_score;
            long left = scores[row * SCORE_STRIDE + column - 1] + gap_score;
            long value = diagonal;
            if (above > value) value = above;
            if (left > value) value = left;
            if (value < 0) value = 0;
            scores[row * SCORE_STRIDE + column] = value;
            if (value > maximum) { maximum = value; max_row = row; max_column = column; }
        }
    }

    long[MAX_TRACE_STEPS] reverse_query = zeroed;
    long[MAX_TRACE_STEPS] reverse_subject = zeroed;
    usz trace_steps = 0;
    usz row = max_row, column = max_column;
    while (row > 0 && column > 0) {
        long current = scores[row * SCORE_STRIDE + column];
        long diagonal = scores[(row - 1) * SCORE_STRIDE + column - 1] +
            pair_score(query[row - 1], subject[column - 1], 1, -1, -2);
        if (current == diagonal) {
            reverse_query[trace_steps] = query[row - 1];
            reverse_subject[trace_steps] = subject[column - 1];
            row--; column--;
        } else if (current == scores[(row - 1) * SCORE_STRIDE + column] - 2) {
            reverse_query[trace_steps] = query[row - 1];
            reverse_subject[trace_steps] = '-';
            row--;
        } else {
            reverse_query[trace_steps] = '-';
            reverse_subject[trace_steps] = subject[column - 1];
            column--;
        }
        trace_steps++;
    }
    char[MAX_ALIGNMENT_BYTES] alignment = zeroed;
    usz alignment_length = 0;
    if (trace_steps > 0) {
        for (usz i = 0; i < trace_steps; i++) alignment[alignment_length++] = (char)reverse_query[trace_steps - i - 1];
        alignment[alignment_length++] = '\n';
        for (usz i = 0; i < trace_steps; i++) alignment[alignment_length++] = (char)reverse_subject[trace_steps - i - 1];
    }

    char[MAX_OUTPUT_BYTES] staged = zeroed;
    write_u32_le(&staged[0], 0, (long)rows);
    write_u32_le(&staged[0], 4, (long)columns);
    usz offset = 8;
    for (usz r = 0; r < rows; r++) {
        for (usz c = 0; c < columns; c++) {
            write_i32_le(&staged[0], offset, scores[r * SCORE_STRIDE + c]);
            offset += 4;
        }
    }
    write_u32_le(&staged[0], offset, (long)alignment_length);
    offset += 4;
    for (usz i = 0; i < alignment_length; i++) staged[offset + i] = alignment[i];
    usz required = offset + alignment_length;
    if (output == null || output_capacity < required) return -2L;
    for (usz i = 0; i < required; i++) output[i] = staged[i];
    return (long)required;
}
