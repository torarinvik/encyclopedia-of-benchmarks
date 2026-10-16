export fn reverse_array(input: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (length < 1 or length > 257) return -1;
    const count = input[0];
    if (count < 1 or count > 256 or length != @as(usize, @intCast(count + 1))) return -1;
    for (0..@as(usize, @intCast(count))) |i| if (input[i + 1] < 0 or input[i + 1] > 255) return -1;
    if (capacity < @as(usize, @intCast(count))) return -2;
    for (0..@as(usize, @intCast(count))) |i| output[i] = @intCast(input[i + 1]);
    var left: usize = 0;
    var right: usize = @as(usize, @intCast(count)) - 1;
    while (left < right) : (left += 1) { const tmp = output[left]; output[left] = output[right]; output[right] = tmp; right -= 1; }
    return count;
}
