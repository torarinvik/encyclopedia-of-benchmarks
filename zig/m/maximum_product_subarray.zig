/// Maximum product of a nonempty contiguous subarray.
const MAX_INPUT_LENGTH: usize = 9;
const INVALID_RESULT: i64 = -9_223_372_036_854_775_807 - 1;

export fn maximum_product_subarray(values: [*c]const i64, length: usize) i64 {
    if (values == null or length == 0 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    for (0..length) |index| {
        if (values[index] < -10 or values[index] > 10) return INVALID_RESULT;
    }

    var current_max = values[0];
    var current_min = values[0];
    var best = values[0];
    for (1..length) |index| {
        const value = values[index];
        const prior_max = current_max;
        const prior_min = current_min;
        const from_max = prior_max * value;
        const from_min = prior_min * value;
        current_max = @max(value, @max(from_max, from_min));
        current_min = @min(value, @min(from_max, from_min));
        best = @max(best, current_max);
    }
    return best;
}
