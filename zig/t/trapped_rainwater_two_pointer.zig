/// Process the smaller endpoint, validating each bar as it enters the window.
export fn trapped_rainwater_two_pointer(heights: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    if (length == 0) return 0;

    var left: usize = 0;
    var right = length - 1;
    var left_height: u64 = @bitCast(heights[left]);
    var right_height: u64 = @bitCast(heights[right]);
    if (left_height > 1_000_000 or right_height > 1_000_000) return -1;

    var left_max: u32 = 0;
    var right_max: u32 = 0;
    var trapped: u32 = 0;
    while (left < right) {
        if (left_height < right_height) {
            const height: u32 = @intCast(left_height);
            left_max = @max(left_max, height);
            trapped += left_max - height;
            left += 1;
            left_height = @bitCast(heights[left]);
            if (left_height > 1_000_000) return -1;
        } else {
            const height: u32 = @intCast(right_height);
            right_max = @max(right_max, height);
            trapped += right_max - height;
            right -= 1;
            right_height = @bitCast(heights[right]);
            if (right_height > 1_000_000) return -1;
        }
    }
    return trapped;
}
