export fn minimum_operations_to_move_all_balls(boxes: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length > 256) return -1;
    var right_ones: i64 = 0;
    var right_distance: i64 = 0;
    for (0..length) |index| {
        const value = boxes[index];
        if (value != 0 and value != 1) return -1;
        if (value == 1) {
            right_ones += 1;
            right_distance += @intCast(index);
        }
    }
    const required_capacity = length * 2;
    if (output_capacity < required_capacity) return -2;
    var left_ones: i64 = 0;
    var left_distance: i64 = 0;
    for (0..length) |index| {
        if (boxes[index] == 1) {
            right_ones -= 1;
            left_ones += 1;
        }
        const distance = left_distance + right_distance;
        output[index * 2] = @intCast(distance & 255);
        output[index * 2 + 1] = @intCast((distance >> 8) & 255);
        right_distance -= right_ones;
        left_distance += left_ones;
    }
    return @intCast(length);
}
