const MAX_TARGET: usize = 8;

fn requiredBytes(remaining: usize, depth: usize) usize {
    if (remaining == 0) return depth + 1;
    var total: usize = 0;
    const maximum_face = @min(remaining, 6);
    for (1..maximum_face + 1) |face| total += requiredBytes(remaining - face, depth + 1);
    return total;
}

fn emitCombinations(remaining: usize, depth: usize, digits: *[MAX_TARGET]u8,
    output: [*]u8, position: *usize) void {
    if (remaining == 0) {
        for (0..depth) |index| {
            output[position.*] = digits[index];
            position.* += 1;
        }
        output[position.*] = '\n';
        position.* += 1;
        return;
    }
    const maximum_face = @min(remaining, 6);
    for (1..maximum_face + 1) |face| {
        digits[depth] = @intCast('0' + face);
        emitCombinations(remaining - face, depth + 1, digits, output, position);
    }
}

export fn dice_thrower(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 1 or values[0] < 0 or values[0] > MAX_TARGET) return -1;
    const target: usize = @intCast(values[0]);
    const needed = requiredBytes(target, 0);
    if (output_capacity < needed or output == null) return -2;
    var digits: [MAX_TARGET]u8 = undefined;
    var position: usize = 0;
    emitCombinations(target, 0, &digits, output, &position);
    return @intCast(position);
}
