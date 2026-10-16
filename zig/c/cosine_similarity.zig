const MAX_STRING_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 132;
const ALPHABET_SIZE: usize = 95;
const INVALID_RESULT: f64 = -1.0e300;

export fn cosine_similarity(input: [*c]const i64, length: usize) f64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const left_length_value = input[0];
    const right_length_value = input[1];
    if (left_length_value < 0 or left_length_value > @as(i64, @intCast(MAX_STRING_LENGTH))
            or right_length_value < 0 or right_length_value > @as(i64, @intCast(MAX_STRING_LENGTH))) return INVALID_RESULT;
    const left_length: usize = @intCast(left_length_value);
    const right_length: usize = @intCast(right_length_value);
    if (length != 2 + left_length + right_length) return INVALID_RESULT;

    var left_counts: [ALPHABET_SIZE]u64 = @splat(0);
    var right_counts: [ALPHABET_SIZE]u64 = @splat(0);
    for (0..left_length) |index| {
        var value = input[2 + index];
        if (value < 32 or value > 126) return INVALID_RESULT;
        if (value >= 65 and value <= 90) value += 32;
        left_counts[@intCast(value - 32)] += 1;
    }
    for (0..right_length) |index| {
        var value = input[2 + left_length + index];
        if (value < 32 or value > 126) return INVALID_RESULT;
        if (value >= 65 and value <= 90) value += 32;
        right_counts[@intCast(value - 32)] += 1;
    }

    var dot_product: f64 = 0.0;
    var left_magnitude_squared: f64 = 0.0;
    var right_magnitude_squared: f64 = 0.0;
    for (0..ALPHABET_SIZE) |index| {
        const left: f64 = @floatFromInt(left_counts[index]);
        const right: f64 = @floatFromInt(right_counts[index]);
        dot_product += left * right;
        left_magnitude_squared += left * left;
        right_magnitude_squared += right * right;
    }
    if (left_magnitude_squared <= 0.0 or right_magnitude_squared <= 0.0) return 0.0;
    return dot_product / (@sqrt(left_magnitude_squared) * @sqrt(right_magnitude_squared));
}
