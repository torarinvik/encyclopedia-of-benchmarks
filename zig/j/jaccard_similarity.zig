/// Return intersection-over-union similarity for two unique ASCII sets.
export fn jaccard_similarity(values: [*]const i64, length: usize) f64 {
    if (length < 2) return -1.0e300;
    const left_value = values[0];
    const right_value = values[1];
    if (left_value < 0 or left_value > 64 or right_value < 0 or right_value > 64
        or (left_value == 0 and right_value == 0)) return -1.0e300;
    const left_length: usize = @intCast(left_value);
    const right_length: usize = @intCast(right_value);
    if (length != 2 + left_length + right_length) return -1.0e300;

    for (0..left_length) |i| {
        const value = values[2 + i];
        if (value < 32 or value > 126) return -1.0e300;
        for (0..i) |before| {
            if (values[2 + before] == value) return -1.0e300;
        }
    }
    for (0..right_length) |i| {
        const value = values[2 + left_length + i];
        if (value < 32 or value > 126) return -1.0e300;
        for (0..i) |before| {
            if (values[2 + left_length + before] == value) return -1.0e300;
        }
    }

    var intersection: usize = 0;
    for (0..left_length) |i| {
        for (0..right_length) |j| {
            if (values[2 + i] == values[2 + left_length + j]) {
                intersection += 1;
                break;
            }
        }
    }
    const union_length = left_length + right_length - intersection;
    return @as(f64, @floatFromInt(intersection)) / @as(f64, @floatFromInt(union_length));
}
