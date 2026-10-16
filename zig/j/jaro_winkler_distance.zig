const MAX_STRING_LENGTH: usize = 32;
const MAX_STRING_LENGTH_I64: i64 = 32;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_STRING_LENGTH;
const SCALE: i64 = 1_000_000_000;

/// C#-faithful Jaro-Winkler distance in billionths, rounded to nearest (ties upward).
pub export fn jaro_winkler_distance(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const first_length_value = input[0];
    if (first_length_value < 0 or first_length_value > MAX_STRING_LENGTH_I64) return -1;
    const first_length: usize = @intCast(first_length_value);
    const second_length_index = 1 + first_length;
    if (second_length_index >= length) return -1;
    const second_length_value = input[second_length_index];
    if (second_length_value < 0 or second_length_value > MAX_STRING_LENGTH_I64 or
        first_length_value < second_length_value or
        length != second_length_index + 1 + @as(usize, @intCast(second_length_value))) return -1;
    const second_length: usize = @intCast(second_length_value);

    for (0..first_length) |i| {
        const value = input[1 + i];
        if (value < 0 or value > 127) return -1;
    }
    for (0..second_length) |i| {
        const value = input[second_length_index + 1 + i];
        if (value < 0 or value > 127) return -1;
    }
    if (first_length == second_length) {
        var equal = true;
        for (0..first_length) |i| {
            if (input[1 + i] != input[second_length_index + 1 + i]) {
                equal = false;
                break;
            }
        }
        if (equal) return 0;
    }
    if (second_length == 0) return SCALE;

    const half = first_length / 2;
    const radius = if (half > 0) half - 1 else 0;
    var first_matched: [MAX_STRING_LENGTH]bool = @splat(false);
    var second_matched: [MAX_STRING_LENGTH]bool = @splat(false);
    var match_count: usize = 0;
    for (0..first_length) |i| {
        const start = if (i > radius) i - radius else 0;
        const ending = @min(i + radius, second_length - 1);
        if (start > ending) continue;
        for (start..ending + 1) |j| {
            if (input[1 + i] == input[second_length_index + 1 + j] and !second_matched[j]) {
                first_matched[i] = true;
                second_matched[j] = true;
                match_count += 1;
                break;
            }
        }
    }
    if (match_count == 0) return SCALE;

    var second_index: usize = 0;
    var mismatched_pairs: usize = 0;
    for (0..first_length) |i| {
        if (!first_matched[i]) continue;
        while (second_index < second_length and !second_matched[second_index]) : (second_index += 1) {}
        if (second_index == second_length) return -1;
        if (input[1 + i] != input[second_length_index + 1 + second_index]) mismatched_pairs += 1;
        second_index += 1;
    }
    const matches: i64 = @intCast(match_count);
    const first_size: i64 = @intCast(first_length);
    const second_size: i64 = @intCast(second_length);
    const transpositions: i64 = @intCast(mismatched_pairs / 2);
    const jaro_numerator = matches * matches * second_size + matches * matches * first_size +
        (matches - transpositions) * first_size * second_size;
    const jaro_denominator: i64 = 3 * first_size * second_size * matches;

    var prefix_length: usize = 0;
    const prefix_limit = @min(second_length, 4);
    while (prefix_length < prefix_limit and input[1 + prefix_length] == input[second_length_index + 1 + prefix_length]) : (prefix_length += 1) {}
    const denominator: i64 = 10 * jaro_denominator;
    const numerator: i64 = @as(i64, @intCast(10 - prefix_length)) * (jaro_denominator - jaro_numerator);
    return @divTrunc(numerator * SCALE + denominator / 2, denominator);
}
