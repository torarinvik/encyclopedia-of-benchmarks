/// Unit-cost Levenshtein distance over two ASCII byte sequences.
export fn levenshtein_distance(values: [*]const i64, length: usize) i64 {
    if (length < 2) return -1;
    const left_length_value = values[0];
    const right_length_value = values[1];
    if (left_length_value < 0 or left_length_value > 255 or
        right_length_value < 0 or right_length_value > 255) return -1;
    const left_length: usize = @intCast(left_length_value);
    const right_length: usize = @intCast(right_length_value);
    if (length != 2 + left_length + right_length) return -1;
    const left = values[2..][0..left_length];
    const right = values[2 + left_length ..][0..right_length];
    for (left) |byte| {
        if (byte < 0 or byte > 127) return -1;
    }
    for (right) |byte| {
        if (byte < 0 or byte > 127) return -1;
    }

    var row: [256]i64 = @splat(0);
    for (0..right_length + 1) |column| row[column] = @intCast(column);
    for (1..left_length + 1) |row_index| {
        var diagonal = row[0];
        row[0] = @intCast(row_index);
        for (1..right_length + 1) |column| {
            const above = row[column];
            const deletion = above + 1;
            const insertion = row[column - 1] + 1;
            const substitution = diagonal + @as(i64, if (left[row_index - 1] == right[column - 1]) 0 else 1);
            row[column] = @min(@min(deletion, insertion), substitution);
            diagonal = above;
        }
    }
    return row[right_length];
}
