/// Check whether two bounded ASCII strings preserve a one-to-one mapping.
const MAX_CODEPOINTS: usize = 8;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_CODEPOINTS + 2;

export fn is_isomorphic(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const source_length = input[0];
    const target_length = input[1];
    if (source_length < 0 or source_length > MAX_CODEPOINTS or
        target_length < 0 or target_length > MAX_CODEPOINTS) return -1;
    const source_count: usize = @intCast(source_length);
    const target_count: usize = @intCast(target_length);
    if (length != 2 + source_count + target_count) return -1;
    for (2..length) |index| {
        const codepoint = input[index];
        if (codepoint < 0 or codepoint > 127) return -1;
    }
    if (source_count != target_count) return 0;

    var source_to_target = [_]i64{-1} ** 128;
    var target_to_source = [_]i64{-1} ** 128;
    for (0..source_count) |index| {
        const source: usize = @intCast(input[2 + index]);
        const target: usize = @intCast(input[2 + source_count + index]);
        if ((source_to_target[source] != -1 and source_to_target[source] != @as(i64, @intCast(target))) or
            (target_to_source[target] != -1 and target_to_source[target] != @as(i64, @intCast(source)))) return 0;
        source_to_target[source] = @intCast(target);
        target_to_source[target] = @intCast(source);
    }
    return 1;
}
