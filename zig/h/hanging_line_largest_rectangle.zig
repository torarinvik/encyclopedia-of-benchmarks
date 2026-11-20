const MAX_LENGTH: usize = 64;
const MAX_HEIGHT: i64 = 1_000_000;
const INVALID_RESULT: i64 = -9_223_372_036_854_775_808;

export fn hanging_line_largest_rectangle(heights: [*c]const i64, length: usize) i64 {
    if (length == 0) return 0;
    if (heights == null or length > MAX_LENGTH) return INVALID_RESULT;
    for (0..length) |i| {
        if (heights[i] < 0 or heights[i] > MAX_HEIGHT) return INVALID_RESULT;
    }

    var left: [MAX_LENGTH]usize = undefined;
    var right: [MAX_LENGTH]usize = undefined;
    for (0..length) |i| {
        left[i] = i;
        while (left[i] > 0 and heights[i] <= heights[left[i] - 1])
            left[i] = left[left[i] - 1];
    }
    var i = length;
    while (i > 0) {
        i -= 1;
        right[i] = i;
        while (right[i] + 1 < length and heights[i] <= heights[right[i] + 1])
            right[i] = right[right[i] + 1];
    }

    var best: i64 = 0;
    for (0..length) |j| {
        const width: i64 = @intCast(right[j] - left[j] + 1);
        best = @max(best, heights[j] * width);
    }
    return best;
}
