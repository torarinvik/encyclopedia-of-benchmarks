const M1: i64 = 4_294_967_087;
const M2: i64 = 4_294_944_443;

fn residue(value: i64, modulus: i64) i64 {
    const result = @rem(value, modulus);
    return if (result < 0) result + modulus else result;
}

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @intCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn mrg32k3a_combined_recursive_generator(
    input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (input == null or length != 7) return -1;
    var x1 = [3]i64{ input[0], input[1], input[2] };
    var x2 = [3]i64{ input[3], input[4], input[5] };
    for (0..3) |index| {
        if (x1[index] < 0 or x1[index] >= M1 or x2[index] < 0 or x2[index] >= M2) return -1;
    }
    if ((x1[0] | x1[1] | x1[2]) == 0 or (x2[0] | x2[1] | x2[2]) == 0) return -1;
    const count_value = input[6];
    if (count_value < 0 or count_value > 64) return -1;
    const count: usize = @intCast(count_value);
    const required = count * 8;
    if (count == 0) return 0;
    if (capacity < required or output == null) return -2;

    for (0..count) |step| {
        const next1 = residue(1_403_580 * x1[1] - 810_728 * x1[0], M1);
        const next2 = residue(527_612 * x2[2] - 1_370_589 * x2[0], M2);
        x1 = .{ x1[1], x1[2], next1 };
        x2 = .{ x2[1], x2[2], next2 };
        var z = next1 - next2;
        if (z < 0) z += M1;
        putI64Le(output, step * 8, z);
    }
    return @intCast(required);
}
