/// Emit fixed-size index combinations as little-endian subset masks.
export fn subset_combinations(input: [*]const i64, length: usize,
                              output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 13 or input[0] < 0) return -1;
    const item_count = length - 1;
    if (item_count > 12) return -1;
    if (input[0] > @as(i64, @intCast(item_count))) return 0;
    const choose: usize = @intCast(input[0]);
    var count: usize = 1;
    for (1..choose + 1) |index| count = count * (item_count - choose + index) / index;
    const required = 2 * count;
    if (output_capacity < required) return -2;
    var indices: [12]usize = @splat(0);
    for (0..choose) |index| indices[index] = index;
    for (0..count) |combination| {
        var mask: usize = 0;
        for (0..choose) |index| mask |= @as(usize, 1) << @intCast(indices[index]);
        output[2 * combination] = @intCast(mask % 256);
        output[2 * combination + 1] = @intCast(mask / 256);
        if (combination + 1 == count) break;
        var position = choose;
        while (position > 0) {
            position -= 1;
            if (indices[position] < item_count - choose + position) break;
        }
        indices[position] += 1;
        for (position + 1..choose) |index| indices[index] = indices[index - 1] + 1;
    }
    return @intCast(count);
}
