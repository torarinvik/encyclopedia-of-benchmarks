/// Port the fixed-size integer matrix multiplication from Stanford IntMM.
const ROWSIZE: usize = 40;
const CELL_COUNT: usize = ROWSIZE * ROWSIZE;
const MAX_PASSES: usize = 10;

fn decimalWidth(value: i32) usize {
    var magnitude: i64 = value;
    if (magnitude < 0) magnitude = -magnitude;
    var width: usize = if (value < 0) 1 else 0;
    while (true) {
        width += 1;
        magnitude = @divTrunc(magnitude, 10);
        if (magnitude == 0) break;
    }
    return width;
}

fn writeDecimal(value: i32, output: [*]u8, start: usize) usize {
    var magnitude: i64 = value;
    var position = start;
    if (magnitude < 0) {
        output[position] = '-';
        position += 1;
        magnitude = -magnitude;
    }
    var reversed: [10]u8 = @splat(0);
    var count: usize = 0;
    while (true) {
        reversed[count] = @intCast(48 + @mod(magnitude, 10));
        count += 1;
        magnitude = @divTrunc(magnitude, 10);
        if (magnitude == 0) break;
    }
    while (count > 0) {
        count -= 1;
        output[position] = reversed[count];
        position += 1;
    }
    return position;
}

export fn stanford_intmm(pass_count: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (pass_count < 1 or pass_count > @as(i64, @intCast(MAX_PASSES))) return -1;
    const pass_total: usize = @intCast(pass_count);

    var a: [CELL_COUNT]i32 = undefined;
    var b: [CELL_COUNT]i32 = undefined;
    var product: [CELL_COUNT]i32 = undefined;
    var diagonal: [MAX_PASSES]i32 = undefined;
    for (0..pass_total) |pass| {
        var seed: i64 = 74755;
        for (0..CELL_COUNT) |index| {
            seed = (seed * 1309 + 13849) & 65535;
            a[index] = @intCast(@mod(seed, 120) - 60);
        }
        for (0..CELL_COUNT) |index| {
            seed = (seed * 1309 + 13849) & 65535;
            b[index] = @intCast(@mod(seed, 120) - 60);
        }

        for (0..ROWSIZE) |row| {
            for (0..ROWSIZE) |column| {
                var sum: i32 = 0;
                for (0..ROWSIZE) |inner| {
                    sum += a[row * ROWSIZE + inner] * b[inner * ROWSIZE + column];
                }
                product[row * ROWSIZE + column] = sum;
            }
        }
        diagonal[pass] = product[pass * ROWSIZE + pass];
    }

    var required: usize = 0;
    for (0..pass_total) |pass| required += decimalWidth(diagonal[pass]) + 1;
    if (output_opt == null or output_capacity < required) return -2;
    const output = output_opt.?;

    var position: usize = 0;
    for (0..pass_total) |pass| {
        position = writeDecimal(diagonal[pass], output, position);
        output[position] = '\n';
        position += 1;
    }
    return @intCast(position);
}
