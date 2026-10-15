const MAX_STRING_LENGTH: usize = 4096;
const MAX_PACKED_LENGTH: usize = 8195;

/// Return the lowercase byte added to t by subtracting the two character sums.
export fn find_the_difference(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_PACKED_LENGTH) return -1;
    if (input[0] < 0 or input[0] > MAX_STRING_LENGTH or
        input[1] < 1 or input[1] > MAX_STRING_LENGTH + 1) return -1;
    const s_length: usize = @intCast(input[0]);
    const t_length: usize = @intCast(input[1]);
    if (t_length != s_length + 1 or length != 2 + s_length + t_length) return -1;
    var sum_s: i64 = 0;
    var sum_t: i64 = 0;
    for (0..s_length) |index| {
        const value = input[2 + index];
        if (value < 97 or value > 122) return -1;
        sum_s += value;
    }
    const t_start = 2 + s_length;
    for (0..t_length) |index| {
        const value = input[t_start + index];
        if (value < 97 or value > 122) return -1;
        sum_t += value;
    }
    const difference = sum_t - sum_s;
    if (difference < 97 or difference > 122) return -1;
    return difference;
}
