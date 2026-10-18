const max_sequence_length: usize = 16;
const max_parseable_input_length: usize = 38;
const score_stride: usize = 17;

export fn smith_waterman_java(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 5 or length > max_parseable_input_length) return -1;
    const query_length_value = values[0];
    const subject_length_value = values[1];
    const match_score = values[2];
    const mismatch_score = values[3];
    const gap_score = values[4];
    if (query_length_value < 0 or query_length_value > max_sequence_length or
        subject_length_value < 0 or subject_length_value > max_sequence_length or
        match_score < 1 or match_score > 5 or mismatch_score < -5 or mismatch_score > -1 or
        gap_score < -5 or gap_score > -1) return -1;
    const query_length: usize = @intCast(query_length_value);
    const subject_length: usize = @intCast(subject_length_value);
    if (length != 5 + query_length + subject_length) return -1;
    for (5..length) |index| {
        const value = values[index];
        if (!((value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z') or value == '-')) return -1;
    }

    var scores = [_]i64{0} ** (score_stride * score_stride);
    var maximum: i64 = 0;
    for (1..query_length + 1) |row| {
        for (1..subject_length + 1) |column| {
            const query_char = values[4 + row];
            const subject_char = values[4 + query_length + column];
            const pair_score = if (query_char == subject_char) match_score else mismatch_score;
            const diagonal = scores[(row - 1) * score_stride + column - 1] + pair_score;
            const above = scores[(row - 1) * score_stride + column] + gap_score;
            const left = scores[row * score_stride + column - 1] + gap_score;
            const value = @max(0, @max(diagonal, @max(above, left)));
            scores[row * score_stride + column] = value;
            maximum = @max(maximum, value);
        }
    }
    return maximum;
}
