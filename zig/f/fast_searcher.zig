const MAX_ARRAY_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 67;

fn searchSegment(input: [*c]const i64, begin: usize, length: usize,
                 target: i64, offset: usize) i64 {
    if (length == 0) return -1;
    const first = input[begin];
    const last = input[begin + length - 1];
    if (target < first or target > last) return -1;
    if (first == last) return if (target == first) @intCast(offset) else -1;

    const interpolation: usize = @intCast(@as(i64, @intCast(length - 1)) * (target - first) / (last - first));
    const midpoint = length / 2;
    const left = @min(interpolation, midpoint);
    const right = @max(interpolation, midpoint);
    var from: usize = 0;
    var to: usize = 0;
    if (target < input[begin + left]) {
        if (left == 0) return -1;
        from = 0;
        to = left - 1;
    } else if (target < input[begin + right]) {
        from = left;
        to = right - 1;
    } else {
        from = right;
        to = length - 1;
    }
    if (to < from) return -1;
    return searchSegment(input, begin + from, to - from + 1, target, offset + from);
}

export fn fast_searcher(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -2;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_ARRAY_LENGTH))) return -2;
    const count: usize = @intCast(input[0]);
    if (length != count + 2) return -2;
    for (0..count) |index| {
        const value = input[1 + index];
        if (value < -1000 or value > 1000) return -2;
        if (index > 0 and input[index] >= value) return -2;
    }
    const target = input[length - 1];
    if (target < -1000 or target > 1000) return -2;
    return searchSegment(input, 1, count, target, 0);
}
