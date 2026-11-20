const MAX_VERTICES: usize = 16;
const MAX_PARSEABLE_LENGTH: usize = 34;
const SCALE: i64 = 1_000_000;

fn roundedMicro(numerator_input: i64, denominator_input: i64) i64 {
    var numerator = numerator_input;
    var denominator = denominator_input;
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
    const sign: i64 = if (numerator < 0) -1 else 1;
    const magnitude: u64 = @intCast(if (numerator < 0) -numerator else numerator);
    const scaled = magnitude * @as(u64, @intCast(SCALE));
    const divisor: u64 = @intCast(denominator);
    var quotient = scaled / divisor;
    if (2 * (scaled % divisor) >= divisor) quotient += 1;
    return sign * @as(i64, @intCast(quotient));
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn polygon_area_centroid(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 7 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?;
    const count_value = input[0];
    if (count_value < 3 or count_value > MAX_VERTICES) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + 2 * count) return -1;

    var xs: [MAX_VERTICES]i64 = @splat(0);
    var ys: [MAX_VERTICES]i64 = @splat(0);
    for (0..count) |i| {
        const x = input[1 + 2 * i];
        const y = input[2 + 2 * i];
        if (x < -50 or x > 50 or y < -50 or y > 50) return -1;
        for (0..i) |j| if (xs[j] == x and ys[j] == y) { return -1; };
        xs[i] = x;
        ys[i] = y;
    }

    var twice_area: i64 = 0;
    for (0..count) |i| {
        const next = (i + 1) % count;
        twice_area += xs[i] * ys[next] - xs[next] * ys[i];
    }
    if (twice_area == 0) return -1;
    const orientation: i64 = if (twice_area > 0) 1 else -1;
    for (0..count) |i| {
        const next = (i + 1) % count;
        for (0..count) |j| {
            if (j == i or j == next) continue;
            const side = (xs[next] - xs[i]) * (ys[j] - ys[i]) -
                (ys[next] - ys[i]) * (xs[j] - xs[i]);
            if (side * orientation <= 0) return -1;
        }
    }

    var numerator_x: i64 = 0;
    var numerator_y: i64 = 0;
    for (0..count) |i| {
        const next = (i + 1) % count;
        const cross = xs[i] * ys[next] - xs[next] * ys[i];
        numerator_x += (xs[i] + xs[next]) * cross;
        numerator_y += (ys[i] + ys[next]) * cross;
    }
    const x_micro = roundedMicro(numerator_x, 3 * twice_area);
    const y_micro = roundedMicro(numerator_y, 3 * twice_area);
    if (output_opt == null or capacity < 16) return -2;
    const output = output_opt.?;
    storeI64Le(output, 0, x_micro);
    storeI64Le(output, 8, y_micro);
    return 16;
}
