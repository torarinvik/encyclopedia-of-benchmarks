const INVALID_RESULT: i64 = -1;
const MAX_INPUT_LENGTH: usize = 259;
const MAX_ARRAY_LENGTH: i64 = 256;
const MAX_DOMAIN_VALUE: i64 = 2_147_483_647;

export fn longest_subarray_with_sum_less_or_equal_to_k(
    input: ?[*]const i64,
    length: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const values = input.?[0..length];
    const target = values[0];
    const raw_count = values[1];
    if (target < 0 or target > MAX_DOMAIN_VALUE or raw_count < 0 or raw_count > MAX_ARRAY_LENGTH)
        return INVALID_RESULT;
    const count: usize = @intCast(raw_count);
    if (length != count + 2) return INVALID_RESULT;

    var total_sum: i64 = 0;
    for (values[2..]) |value| {
        if (value < 0 or value > MAX_DOMAIN_VALUE) return INVALID_RESULT;
        total_sum += value;
    }
    if (total_sum > MAX_DOMAIN_VALUE) return INVALID_RESULT;

    var left: usize = 0;
    var best_length: usize = 0;
    var window_sum: i64 = 0;
    for (0..count) |right| {
        window_sum += values[right + 2];
        while (window_sum > target and left <= right) {
            window_sum -= values[left + 2];
            left += 1;
        }
        const current_length: usize = if (left <= right) right - left + 1 else 0;
        best_length = @max(best_length, current_length);
    }
    return @intCast(best_length);
}
