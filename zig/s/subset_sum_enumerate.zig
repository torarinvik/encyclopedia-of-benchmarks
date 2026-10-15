/// Emit the index masks of all signed subsets matching the target.
export fn subset_sum_enumerate(input: [*]const i64, length: usize,
                               output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 9) return -1;
    const target = input[0];
    if (target < -512 or target > 512) return -1;
    const items = length - 1;
    for (0..items) |index| {
        if (input[index + 1] < -64 or input[index + 1] > 64) return -1;
    }
    var masks: [256]u8 = @splat(0);
    var count: usize = 0;
    const limit = @as(usize, 1) << @intCast(items);
    for (0..limit) |mask| {
        var sum: i64 = 0;
        var bit: usize = 1;
        for (0..items) |index| {
            if (mask / bit % 2 == 1) sum += input[index + 1];
            bit *= 2;
        }
        if (sum == target) {
            masks[count] = @intCast(mask);
            count += 1;
        }
    }
    if (output_capacity < count) return -2;
    for (0..count) |index| output[index] = masks[index];
    return @intCast(count);
}
