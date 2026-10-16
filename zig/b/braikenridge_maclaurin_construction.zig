/// Compute the six exact 5x5 determinant coefficients of a conic.
fn determinant(features: *const [5][6]i64, coefficient: usize) i64 {
    const columns = [_]usize{
        1, 2, 3, 4, 5, 0, 2, 3, 4, 5, 0, 1, 3, 4, 5,
        0, 1, 2, 4, 5, 0, 1, 2, 3, 5, 0, 1, 2, 3, 4,
    };
    var paths: [32]i64 = @splat(0);
    paths[0] = 1;
    for (0..5) |row| {
        var next: [32]i64 = @splat(0);
        for (0..32) |mask| {
            var selected: usize = 0;
            for (0..5) |bit_index| {
                const shift: u6 = @intCast(bit_index);
                selected += (mask >> shift) & 1;
            }
            if (selected != row or paths[mask] == 0) continue;
            for (0..5) |column| {
                const column_shift: u6 = @intCast(column);
                const bit = @as(usize, 1) << column_shift;
                if ((mask & bit) != 0) continue;
                var inversions: usize = 0;
                for (column + 1..5) |previous| {
                    const shift: u6 = @intCast(previous);
                    inversions += (mask >> shift) & 1;
                }
                const term = paths[mask] * features[row][columns[coefficient * 5 + column]];
                next[mask | bit] += if ((inversions & 1) == 0) term else -term;
            }
        }
        paths = next;
    }
    return paths[31];
}

pub export fn braikenridge_maclaurin_construction(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length != 10) return -2;
    var features: [5][6]i64 = @splat(@splat(0));
    for (0..5) |point| {
        const x = values[2 * point];
        const y = values[2 * point + 1];
        if (x < -10 or x > 10 or y < -10 or y > 10) return -2;
        features[point] = .{ x * x, x * y, y * y, x, y, 1 };
    }
    const signs = [_]i64{ 1, -1, 1, -1, 1, -1 };
    var coefficients: [6]i64 = @splat(0);
    for (0..6) |index| coefficients[index] = signs[index] * determinant(&features, index);
    if (output_capacity < 48) return -2;
    for (0..6) |index| {
        const bits: u64 = @bitCast(coefficients[index]);
        for (0..8) |byte| {
            const shift: u6 = @intCast(byte * 8);
            output[index * 8 + byte] = @truncate(bits >> shift);
        }
    }
    return 6;
}
