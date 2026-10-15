/// Return one minus character-set Jaccard similarity for two ASCII strings.
export fn jaccard_distance(values: [*]const i64, length: usize) f64 {
    if (length < 2) return -1.0e300;
    const left_value = values[0];
    const right_value = values[1];
    if (left_value < 0 or left_value > 64 or right_value < 0 or right_value > 64) return -1.0e300;
    const left_length: usize = @intCast(left_value);
    const right_length: usize = @intCast(right_value);
    if (length != 2 + left_length + right_length) return -1.0e300;
    for (0..left_length) |i| if (values[2 + i] < 32 or values[2 + i] > 126) return -1.0e300;
    for (0..right_length) |j| if (values[2 + left_length + j] < 32 or values[2 + left_length + j] > 126) return -1.0e300;
    const left = values[2 .. 2 + left_length];
    const right = values[2 + left_length .. length];

    var intersection: usize = 0;
    var union_length: usize = 0;
    for (0..left_length) |i| {
        var seen_before = false;
        for (0..i) |k| if (left[k] == left[i]) { seen_before = true; break; };
        if (seen_before) continue;
        union_length += 1;
        for (0..right_length) |j| if (left[i] == right[j]) { intersection += 1; break; };
    }
    for (0..right_length) |j| {
        var seen_before = false;
        for (0..j) |k| if (right[k] == right[j]) { seen_before = true; break; };
        if (seen_before) continue;
        var in_left = false;
        for (0..left_length) |i| if (left[i] == right[j]) { in_left = true; break; };
        if (!in_left) union_length += 1;
    }
    if (union_length == 0) return 0.0;
    return 1.0 - @as(f64, @floatFromInt(intersection)) / @as(f64, @floatFromInt(union_length));
}
