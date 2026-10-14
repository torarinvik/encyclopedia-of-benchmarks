/// Recursively emit the canonical Tower of Hanoi move sequence.
fn emitHanoi(disks: usize, source: u8, destination: u8, auxiliary: u8,
    output: [*]u8, position: usize) usize {
    if (disks == 0) return position;
    const after_first = emitHanoi(disks - 1, source, auxiliary, destination, output, position);
    output[after_first] = source;
    output[after_first + 1] = destination;
    return emitHanoi(disks - 1, auxiliary, destination, source, output, after_first + 2);
}

export fn tower_of_hanoi(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length != 4) return -1;
    if (values[0] < 0 or values[0] > 12) return -1;
    for (1..4) |index| {
        if (values[index] < 0 or values[index] > 2) return -1;
    }
    if (values[1] == values[2] or values[1] == values[3] or values[2] == values[3]) return -1;
    const disks: usize = @intCast(values[0]);
    const move_count = (@as(usize, 1) << @intCast(disks)) - 1;
    const required = move_count * 2;
    if (output_capacity < required) return -2;
    _ = emitHanoi(disks, @intCast(values[1]), @intCast(values[2]), @intCast(values[3]), output, 0);
    return @intCast(move_count);
}
