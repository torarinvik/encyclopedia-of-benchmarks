/// Kadane-based maximum nonempty contiguous circular-subarray sum.
const MAX_INPUT_LENGTH: usize = 64;
const INVALID_RESULT: i64 = -9_223_372_036_854_775_807 - 1;

export fn maximum_circular_subarray(values: [*c]const i64, length: usize) i64 {
    if (values == null or length == 0 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    for (0..length) |index| {
        if (values[index] < -1_000_000 or values[index] > 1_000_000) return INVALID_RESULT;
    }

    var total = values[0];
    var current_max = values[0];
    var max_so_far = values[0];
    var current_min = values[0];
    var min_so_far = values[0];
    for (1..length) |index| {
        const value = values[index];
        current_max = @max(current_max + value, value);
        max_so_far = @max(max_so_far, current_max);
        current_min = @min(current_min + value, value);
        min_so_far = @min(min_so_far, current_min);
        total += value;
    }
    if (min_so_far == total) return max_so_far;
    return @max(max_so_far, total - min_so_far);
}
