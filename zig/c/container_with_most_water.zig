/// Two-pointer maximum area between vertical lines.
export fn container_with_most_water(heights: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    if (length == 0) return 0;
    for (0..length) |index| {
        if (heights[index] < 0 or heights[index] > 2147483647) return -1;
    }
    if (length < 2) return 0;

    var left: usize = 0;
    var right: usize = length - 1;
    var best: i64 = 0;
    while (left < right) {
        const left_height = heights[left];
        const right_height = heights[right];
        const height = @min(left_height, right_height);
        const area = height * @as(i64, @intCast(right - left));
        if (area > best) best = area;
        if (left_height <= right_height) left += 1 else right -= 1;
    }
    return best;
}
