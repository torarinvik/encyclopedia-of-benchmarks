/// Maximize one repeated binary answer while changing at most k entries.
const MAX_BITS: usize = 1024;

fn longestForTarget(input: [*]const i64, count: usize, allowed: usize, target: i64) usize {
    var left: usize = 0;
    var opposite: usize = 0;
    var best: usize = 0;
    var right: usize = 0;
    while (right < count) : (right += 1) {
        if (input[right + 1] != target) opposite += 1;
        while (opposite > allowed) {
            if (input[left + 1] != target) opposite -= 1;
            left += 1;
        }
        best = @max(best, right - left + 1);
    }
    return best;
}

export fn max_consecutive_answers(input: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_BITS + 1) return -1;
    const count = length - 1;
    if (input[0] < 0 or input[0] > count) return -1;
    for (0..count) |index| {
        if (input[index + 1] != 0 and input[index + 1] != 1) return -1;
    }
    const allowed: usize = @intCast(input[0]);
    return @intCast(@max(longestForTarget(input, count, allowed, 1),
                         longestForTarget(input, count, allowed, 0)));
}
