/// Memoized endpoint recurrence, evaluated bottom-up from right to left.
const MAX_LENGTH: usize = 4096;

export fn longest_valid_parentheses(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_LENGTH or (length != 0 and input == null)) return -1;
    for (0..length) |index| {
        if (input[index] != 40 and input[index] != 41) return -1;
    }

    var end_exclusive: [MAX_LENGTH]usize = @splat(0);
    var best: usize = 0;
    var remaining = length;
    while (remaining > 0) {
        remaining -= 1;
        const index = remaining;
        if (input[index] == 40) {
            if (index + 1 < length and input[index + 1] == 41) {
                end_exclusive[index] = index + 2;
                if (index + 2 < length and end_exclusive[index + 2] > end_exclusive[index]) {
                    end_exclusive[index] = end_exclusive[index + 2];
                }
            } else if (index + 1 < length) {
                const nested_end = end_exclusive[index + 1];
                if (nested_end > 0 and nested_end < length and input[nested_end] == 41) {
                    end_exclusive[index] = nested_end + 1;
                    if (nested_end + 1 < length and end_exclusive[nested_end + 1] > end_exclusive[index]) {
                        end_exclusive[index] = end_exclusive[nested_end + 1];
                    }
                }
            }
        }
        if (end_exclusive[index] > index) best = @max(best, end_exclusive[index] - index);
    }
    return @intCast(best);
}
