/// Sum trapped water using per-position prefix and suffix maxima.
export fn trapped_rainwater(heights: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    for (0..length) |index| {
        if (heights[index] < 0 or heights[index] > 1_000_000) return -1;
    }
    if (length < 3) return 0;

    var left_max: [4096]i64 = @splat(0);
    var right_max: [4096]i64 = @splat(0);
    left_max[0] = heights[0];
    for (1..length) |index| left_max[index] = @max(left_max[index - 1], heights[index]);
    right_max[length - 1] = heights[length - 1];
    var index = length - 1;
    while (index > 0) {
        index -= 1;
        right_max[index] = @max(right_max[index + 1], heights[index]);
    }

    var water: i64 = 0;
    for (0..length) |position| water += @min(left_max[position], right_max[position]) - heights[position];
    return water;
}
