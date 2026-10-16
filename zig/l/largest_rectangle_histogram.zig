/// Largest rectangle area in a bounded histogram.
const MAX_INPUT_LENGTH: usize = 64;
const INVALID_RESULT: i64 = -9_223_372_036_854_775_807 - 1;

export fn largest_rectangle_histogram(heights: [*c]const i64, length: usize) i64 {
    if (length == 0) return 0;
    if (heights == null or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    for (0..length) |index| {
        if (heights[index] < 0 or heights[index] > 1_000_000) return INVALID_RESULT;
    }

    var stack: [MAX_INPUT_LENGTH]usize = undefined;
    var top: usize = 0;
    var best: i64 = 0;
    for (0..length) |index| {
        while (top > 0 and heights[stack[top - 1]] > heights[index]) {
            top -= 1;
            const bar = stack[top];
            const left: usize = if (top == 0) 0 else stack[top - 1] + 1;
            best = @max(best, heights[bar] * @as(i64, @intCast(index - left)));
        }
        stack[top] = index;
        top += 1;
    }
    while (top > 0) {
        top -= 1;
        const bar = stack[top];
        const left: usize = if (top == 0) 0 else stack[top - 1] + 1;
        best = @max(best, heights[bar] * @as(i64, @intCast(length - left)));
    }
    return best;
}
