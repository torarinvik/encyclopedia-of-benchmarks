// Uncompiled and unexecuted Cartesian-tree histogram draft.
export fn cartesian_histogram_area(input_opt: ?[*]const i64, length: usize) i64 {
    if (length == 0) return 0;
    if (input_opt == null or length > 64) return -9223372036854775807-1;
    const heights = input_opt.?;
    for (0..length) |i| if (heights[i] < 0 or heights[i] > 1000000) { return -9223372036854775807-1; };
    var left: [64]usize = undefined;
    var right: [64]usize = undefined;
    var stack: [64]usize = undefined;
    var order: [64]usize = undefined;
    var sizes: [64]usize = @splat(0);
    for (0..length) |i| { left[i] = length; right[i] = length; }
    var top: usize = 0;
    for (0..length) |i| {
        var last = length;
        while (top > 0 and heights[stack[top-1]] > heights[i]) { top -= 1; last = stack[top]; }
        if (top > 0) right[stack[top-1]] = i;
        left[i] = last; stack[top] = i; top += 1;
    }
    const root = stack[0]; top = 1; stack[0] = root;
    var used: usize = 0;
    while (top > 0) {
        top -= 1; const node = stack[top]; order[used] = node; used += 1;
        if (left[node] < length) { stack[top] = left[node]; top += 1; }
        if (right[node] < length) { stack[top] = right[node]; top += 1; }
    }
    var best: i64 = 0;
    while (used > 0) {
        used -= 1; const node = order[used]; sizes[node] = 1;
        if (left[node] < length) sizes[node] += sizes[left[node]];
        if (right[node] < length) sizes[node] += sizes[right[node]];
        const area = heights[node] * @as(i64, @intCast(sizes[node]));
        if (area > best) best = area;
    }
    return best;
}
