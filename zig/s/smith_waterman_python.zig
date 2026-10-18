const MAX_SEQUENCE_LENGTH: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 38;
const SCORE_STRIDE: usize = 17;
const MAX_OUTPUT_BYTES: usize = 1233;

fn putU32LE(output: *[MAX_OUTPUT_BYTES]u8, position: *usize, value: u32) void {
    var bits = value;
    for (0..4) |_| {
        output[position.*] = @truncate(bits);
        bits >>= 8;
        position.* += 1;
    }
}

fn putI32LE(output: *[MAX_OUTPUT_BYTES]u8, position: *usize, value: i32) void {
    putU32LE(output, position, @bitCast(value));
}

export fn smith_waterman_python(input_opt: ?[*]const i64, input_length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (input_length < 5 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const query_length_value = input[0];
    const subject_length_value = input[1];
    const match_score = input[2];
    const mismatch_score = input[3];
    const gap_score = input[4];
    if (query_length_value < 0 or query_length_value > 16 or
        subject_length_value < 0 or subject_length_value > 16 or
        match_score < 1 or match_score > 5 or mismatch_score < -5 or mismatch_score > -1 or
        gap_score < -5 or gap_score > -1) return -1;
    const query_length: usize = @intCast(query_length_value);
    const subject_length: usize = @intCast(subject_length_value);
    if (input_length != 5 + query_length + subject_length) return -1;

    var query = [_]u8{0} ** MAX_SEQUENCE_LENGTH;
    var subject = [_]u8{0} ** MAX_SEQUENCE_LENGTH;
    for (0..query_length + subject_length) |index| {
        var value = input[5 + index];
        if (!((value >= 65 and value <= 90) or (value >= 97 and value <= 122) or value == 45)) return -1;
        if (value >= 97 and value <= 122) value -= 32;
        if (index < query_length) query[index] = @intCast(value) else subject[index - query_length] = @intCast(value);
    }

    var scores = [_]i32{0} ** (SCORE_STRIDE * SCORE_STRIDE);
    for (1..query_length + 1) |row| {
        for (1..subject_length + 1) |column| {
            const query_char = query[row - 1];
            const subject_char = subject[column - 1];
            const pair_score: i32 = if (query_char == '-' or subject_char == '-') @intCast(gap_score)
                else if (query_char == subject_char) @intCast(match_score)
                else @intCast(mismatch_score);
            const diagonal = scores[(row - 1) * SCORE_STRIDE + column - 1] + pair_score;
            const above = scores[(row - 1) * SCORE_STRIDE + column] + @as(i32, @intCast(gap_score));
            const left = scores[row * SCORE_STRIDE + column - 1] + @as(i32, @intCast(gap_score));
            scores[row * SCORE_STRIDE + column] = @max(0, @max(diagonal, @max(above, left)));
        }
    }

    var maximum: i32 = -1;
    var maximum_row: usize = 0;
    var maximum_column: usize = 0;
    for (0..query_length + 1) |row| {
        for (0..subject_length + 1) |column| {
            const value = scores[row * SCORE_STRIDE + column];
            if (value > maximum) {
                maximum = value;
                maximum_row = row;
                maximum_column = column;
            }
        }
    }

    var trace_query = [_]u8{0} ** (2 * MAX_SEQUENCE_LENGTH);
    var trace_subject = [_]u8{0} ** (2 * MAX_SEQUENCE_LENGTH);
    var trace_length: usize = 0;
    var row = maximum_row;
    var column = maximum_column;
    while (row > 0 and column > 0) {
        const query_char = query[row - 1];
        const subject_char = subject[column - 1];
        const pair_score: i32 = if (query_char == '-' or subject_char == '-') -2
            else if (query_char == subject_char) 1
            else -1;
        const current_score = scores[row * SCORE_STRIDE + column];
        const diagonal_score = scores[(row - 1) * SCORE_STRIDE + column - 1] + pair_score;
        if (current_score == diagonal_score) {
            trace_query[trace_length] = query_char;
            trace_subject[trace_length] = subject_char;
            row -= 1;
            column -= 1;
        } else if (current_score == scores[(row - 1) * SCORE_STRIDE + column] - 2) {
            trace_query[trace_length] = query_char;
            trace_subject[trace_length] = '-';
            row -= 1;
        } else {
            trace_query[trace_length] = '-';
            trace_subject[trace_length] = subject_char;
            column -= 1;
        }
        trace_length += 1;
    }

    const alignment_length: usize = if (trace_length == 0) 0 else 2 * trace_length + 1;
    var staged = [_]u8{0} ** MAX_OUTPUT_BYTES;
    var position: usize = 0;
    putU32LE(&staged, &position, @intCast(query_length + 1));
    putU32LE(&staged, &position, @intCast(subject_length + 1));
    for (0..query_length + 1) |matrix_row| {
        for (0..subject_length + 1) |matrix_column| {
            putI32LE(&staged, &position, scores[matrix_row * SCORE_STRIDE + matrix_column]);
        }
    }
    putU32LE(&staged, &position, @intCast(alignment_length));
    for (0..trace_length) |index| {
        staged[position] = trace_query[trace_length - 1 - index];
        position += 1;
    }
    if (trace_length > 0) {
        staged[position] = '\n';
        position += 1;
    }
    for (0..trace_length) |index| {
        staged[position] = trace_subject[trace_length - 1 - index];
        position += 1;
    }

    const output = output_opt orelse return -2;
    if (output_capacity < position) return -2;
    @memcpy(output[0..position], staged[0..position]);
    return @intCast(position);
}
