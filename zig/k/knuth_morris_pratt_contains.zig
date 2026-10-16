/// Return whether a pattern occurs using Knuth-Morris-Pratt matching.
export fn knuth_morris_pratt_contains(input_values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 8194) return -1;
    if (input_values[0] < 0 or input_values[0] > 4096 or input_values[1] < 0 or input_values[1] > 4096) return -1;
    const text_length: usize = @intCast(input_values[0]);
    const pattern_length: usize = @intCast(input_values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (0..text_length + pattern_length) |index| {
        if (input_values[2 + index] < 0 or input_values[2 + index] > 127) return -1;
    }
    if (pattern_length == 0) return 0;

    const pattern_start = 2 + text_length;
    var prefix: [4096]usize = @splat(0);
    var matched: usize = 0;
    for (1..pattern_length) |index| {
        while (matched > 0 and input_values[pattern_start + index] != input_values[pattern_start + matched]) {
            matched = prefix[matched - 1];
        }
        if (input_values[pattern_start + index] == input_values[pattern_start + matched]) matched += 1;
        prefix[index] = matched;
    }

    matched = 0;
    for (0..text_length) |index| {
        while (matched > 0 and input_values[2 + index] != input_values[pattern_start + matched]) {
            matched = prefix[matched - 1];
        }
        if (input_values[2 + index] == input_values[pattern_start + matched]) matched += 1;
        if (matched == pattern_length) return 1;
    }
    return 0;
}
