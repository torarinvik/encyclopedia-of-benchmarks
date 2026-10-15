/// Sum trapped water by advancing the side with the smaller current boundary.
const MAX_LENGTH: usize = 4096;

export fn trapped_rainwater_two_pointer(heights: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    for (0..length) |index| {
        if (heights[index] < 0 or heights[index] > 1_000_000) return -1;
    }
    if (length <= 2) return 0;

    var left: usize = 0;
    var right: usize = length - 1;
    var left_max: u32 = 0;
    var right_max: u32 = 0;
    var trapped: u32 = 0;
    while (left < right) {
        if (heights[left] < heights[right]) {
            const height: u32 = @intCast(heights[left]);
            if (height >= left_max) {
                left_max = height;
            } else {
                trapped += left_max - height;
            }
            left += 1;
        } else {
            const height: u32 = @intCast(heights[right]);
            if (height >= right_max) {
                right_max = height;
            } else {
                trapped += right_max - height;
            }
            right -= 1;
        }
    }
    return @intCast(trapped);
}
