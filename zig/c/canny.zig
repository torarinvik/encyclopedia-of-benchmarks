const MAX_SIDE: usize = 16;
const MAX_PIXELS: usize = MAX_SIDE * MAX_SIDE;
const NORM_SCALE: i64 = 1_048_576;
const ANGLE_SCALE: i64 = 1_000_000_000;
const TAN_22_5_Q9: i64 = 414_213_562;
const GAUSSIAN = [_]i64{
    85_321, 66_110, 30_754, 8_589, 1_440,
    66_110, 51_225, 23_829, 6_655, 1_116,
    30_754, 23_829, 11_085, 3_096, 519,
    8_589, 6_655, 3_096, 865, 145,
    1_440, 1_116, 519, 145, 24,
};
const SOBEL_X = [_]i64{ -1, 0, 1, -2, 0, 2, -1, 0, 1 };
const SOBEL_Y = [_]i64{ 1, 2, 1, 0, 0, 0, -1, -2, -1 };

fn clampCoordinate(coordinate: isize, side: usize) usize {
    if (coordinate < 0) return 0;
    if (coordinate >= @as(isize, @intCast(side))) return side - 1;
    return @intCast(coordinate);
}

fn integerSqrt(value: u64) u64 {
    if (value < 2) return value;
    var low: u64 = 1;
    var high: u64 = @min(value, 4_294_967_296);
    while (low <= high) {
        const middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle + 1 else high = middle - 1;
    }
    return high;
}

export fn canny(values: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > 1 + MAX_PIXELS) return -1;
    const side_value = values[0];
    if (side_value < 1 or side_value > MAX_SIDE) return -1;
    const side: usize = @intCast(side_value);
    const pixels = side * side;
    if (length != pixels + 1) return -1;
    for (0..pixels) |index| {
        if (values[index + 1] < 0 or values[index + 1] > 255) return -1;
    }
    if (output_capacity < pixels or output == null) return -2;

    var blurred: [MAX_PIXELS]i64 = @splat(0);
    var gradient_x: [MAX_PIXELS]i64 = @splat(0);
    var gradient_y: [MAX_PIXELS]i64 = @splat(0);
    var normalized_x: [MAX_PIXELS]i64 = @splat(0);
    var normalized_y: [MAX_PIXELS]i64 = @splat(0);
    var magnitude: [MAX_PIXELS]i64 = @splat(0);
    var destination: [MAX_PIXELS]i64 = @splat(0);

    for (0..side) |row| {
        for (0..side) |column| {
            var total: i64 = 0;
            for (0..9) |ky_index| {
                const ky: isize = @as(isize, @intCast(ky_index)) - 4;
                const source_row = clampCoordinate(@as(isize, @intCast(row)) + ky, side);
                for (0..9) |kx_index| {
                    const kx: isize = @as(isize, @intCast(kx_index)) - 4;
                    const source_column = clampCoordinate(@as(isize, @intCast(column)) + kx, side);
                    const ay: usize = @intCast(if (ky < 0) -ky else ky);
                    const ax: usize = @intCast(if (kx < 0) -kx else kx);
                    total += GAUSSIAN[ay * 5 + ax] * values[1 + source_row * side + source_column];
                }
            }
            blurred[row * side + column] = total;
        }
    }

    var maximum_x: i64 = 0;
    var maximum_y: i64 = 0;
    for (0..side) |row| {
        for (0..side) |column| {
            var total_x: i64 = 0;
            var total_y: i64 = 0;
            for (0..3) |ky_index| {
                const ky: isize = @as(isize, @intCast(ky_index)) - 1;
                const source_row = clampCoordinate(@as(isize, @intCast(row)) + ky, side);
                for (0..3) |kx_index| {
                    const kx: isize = @as(isize, @intCast(kx_index)) - 1;
                    const source_column = clampCoordinate(@as(isize, @intCast(column)) + kx, side);
                    const sample = blurred[source_row * side + source_column];
                    const kernel_index: usize = @intCast((ky + 1) * 3 + kx + 1);
                    total_x += sample * SOBEL_X[kernel_index];
                    total_y += sample * SOBEL_Y[kernel_index];
                }
            }
            const offset = row * side + column;
            gradient_x[offset] = @intCast(if (total_x < 0) -total_x else total_x);
            gradient_y[offset] = @intCast(if (total_y < 0) -total_y else total_y);
            maximum_x = @max(maximum_x, gradient_x[offset]);
            maximum_y = @max(maximum_y, gradient_y[offset]);
        }
    }

    var maximum_magnitude: u64 = 0;
    for (0..pixels) |index| {
        if (maximum_x != 0) normalized_x[index] = @divTrunc(gradient_x[index] * 255 * NORM_SCALE, maximum_x);
        if (maximum_y != 0) normalized_y[index] = @divTrunc(gradient_y[index] * 255 * NORM_SCALE, maximum_y);
        const x: u64 = @intCast(normalized_x[index]);
        const y: u64 = @intCast(normalized_y[index]);
        magnitude[index] = @intCast(integerSqrt(x * x + y * y));
        maximum_magnitude = @max(maximum_magnitude, @as(u64, @intCast(magnitude[index])));
    }
    if (maximum_magnitude != 0) {
        for (0..pixels) |index| {
            magnitude[index] = @divTrunc(magnitude[index] * 255, @as(i64, @intCast(maximum_magnitude)));
        }
    }

    var row: usize = 1;
    while (row + 1 < side) : (row += 1) {
        var column: usize = 1;
        while (column + 1 < side) : (column += 1) {
            const offset = row * side + column;
            var before = offset - 1;
            var after = offset + 1;
            if (normalized_y[offset] * ANGLE_SCALE >= normalized_x[offset] * TAN_22_5_Q9) {
                if (normalized_x[offset] * ANGLE_SCALE <= normalized_y[offset] * TAN_22_5_Q9) {
                    before = offset - side;
                    after = offset + side;
                } else {
                    before = offset + side - 1;
                    after = offset - side + 1;
                }
            }
            if (magnitude[offset] >= magnitude[before] and magnitude[offset] >= magnitude[after]) {
                destination[offset] = magnitude[offset];
            }
        }
    }

    for (0..pixels) |index| {
        if (destination[index] >= 30) destination[index] = 255
        else if (destination[index] <= 15) destination[index] = 0
        else destination[index] = 128;
    }
    row = 1;
    while (row + 1 < side) : (row += 1) {
        var column: usize = 1;
        while (column + 1 < side) : (column += 1) {
            const offset = row * side + column;
            if (destination[offset] == 128) {
                var connected = false;
                for (0..3) |dy_index| {
                    const dy: isize = @as(isize, @intCast(dy_index)) - 1;
                    for (0..3) |dx_index| {
                        const dx: isize = @as(isize, @intCast(dx_index)) - 1;
                        if ((dx != 0 or dy != 0)
                            and destination[@as(usize, @intCast(@as(isize, @intCast(row)) + dy)) * side
                                + @as(usize, @intCast(@as(isize, @intCast(column)) + dx))] == 255)
                            connected = true;
                    }
                }
                destination[offset] = if (connected) 255 else 0;
            }
        }
    }
    for (0..pixels) |index| output[index] = @intCast(destination[index]);
    return @intCast(pixels);
}
