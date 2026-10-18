module smith_waterman_java;

const usz MAX_SEQUENCE_LENGTH = 16;
const usz MAX_PARSEABLE_INPUT_LENGTH = 38;
const usz SCORE_STRIDE = 17;

fn long smith_waterman_java(long* input, usz length) @export("smith_waterman_java") {
    if (input == null || length < 5 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long query_length_value = input[0];
    long subject_length_value = input[1];
    long match_score = input[2];
    long mismatch_score = input[3];
    long gap_score = input[4];
    if (query_length_value < 0 || (usz)query_length_value > MAX_SEQUENCE_LENGTH ||
        subject_length_value < 0 || (usz)subject_length_value > MAX_SEQUENCE_LENGTH ||
        match_score < 1 || match_score > 5 || mismatch_score < -5 || mismatch_score > -1 ||
        gap_score < -5 || gap_score > -1) return -1;
    usz query_length = (usz)query_length_value;
    usz subject_length = (usz)subject_length_value;
    if (length != 5 + query_length + subject_length) return -1;
    for (usz index = 5; index < length; index++) {
        long value = input[index];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') || value == '-')) return -1;
    }

    long[SCORE_STRIDE * SCORE_STRIDE] scores = {0};
    long maximum = 0;
    for (usz row = 1; row <= query_length; row++) {
        for (usz column = 1; column <= subject_length; column++) {
            long query_char = input[4 + row];
            long subject_char = input[4 + query_length + column];
            long pair_score = query_char == subject_char ? match_score : mismatch_score;
            long diagonal = scores[(row - 1) * SCORE_STRIDE + column - 1] + pair_score;
            long above = scores[(row - 1) * SCORE_STRIDE + column] + gap_score;
            long left = scores[row * SCORE_STRIDE + column - 1] + gap_score;
            long value = diagonal;
            if (above > value) value = above;
            if (left > value) value = left;
            if (value < 0) value = 0;
            scores[row * SCORE_STRIDE + column] = value;
            if (value > maximum) maximum = value;
        }
    }
    return maximum;
}
