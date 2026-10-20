const MAX_OUTPUT_BYTES: usize = 152;
const COORDINATE_SCALE: i64 = 1_000_000;
const PI_VALUE: f64 = 3.14159265358979323846264338327950288;

fn orient(ax: i64, ay: i64, bx: i64, by: i64, cx: i64, cy: i64) i64 {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

fn roundRatioAway(numerator: i64, denominator: i64) i64 {
    const magnitude = if (numerator < 0) -numerator else numerator;
    const rounded = @divTrunc(magnitude + @divTrunc(denominator, 2), denominator);
    return if (numerator < 0) -rounded else rounded;
}

fn putI64(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn delaunay_mesh_refinement(values: [*c]const i64, length: usize,
                                   output: [*c]u8, capacity: usize) i64 {
    if (values == null or length != 7 or values[0] != 3) return -1;
    var x: [3]i64 = @splat(0);
    var y: [3]i64 = @splat(0);
    for (0..3) |i| {
        x[i] = values[1 + 2 * i];
        y[i] = values[2 + 2 * i];
        if (x[i] < -100 or x[i] > 100 or y[i] < -100 or y[i] > 100) return -1;
        for (0..i) |j| if (x[i] == x[j] and y[i] == y[j]) return -1;
    }
    const area2 = orient(x[0], y[0], x[1], y[1], x[2], y[2]);
    if (area2 <= 0) return -1;
    for (0..3) |i| {
        const j = (i + 1) % 3;
        const k = (i + 2) % 3;
        const ux = x[j] - x[i]; const uy = y[j] - y[i];
        const vx = x[k] - x[i]; const vy = y[k] - y[i];
        if (ux * vx + uy * vy <= 0) return -1;
    }
    const len01 = @sqrt(@as(f64, @floatFromInt((x[1]-x[0])*(x[1]-x[0]) + (y[1]-y[0])*(y[1]-y[0]))));
    const len12 = @sqrt(@as(f64, @floatFromInt((x[2]-x[1])*(x[2]-x[1]) + (y[2]-y[1])*(y[2]-y[1]))));
    const len20 = @sqrt(@as(f64, @floatFromInt((x[0]-x[2])*(x[0]-x[2]) + (y[0]-y[2])*(y[0]-y[2]))));
    const shortest = @min(len01, @min(len12, len20));
    const ratio = len01 * len12 * len20 / (2.0 * @as(f64, @floatFromInt(area2)) * shortest);
    const beta = 1.0 / (2.0 * @sin(PI_VALUE / 9.0));
    const refine = ratio > beta * (1.0 + 1e-12);

    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    putI64(&staged, 0, if (refine) 4 else 3);
    for (0..3) |i| {
        putI64(&staged, 8 + 16 * i, x[i] * COORDINATE_SCALE);
        putI64(&staged, 16 + 16 * i, y[i] * COORDINATE_SCALE);
    }
    if (refine) {
        const ax = x[0]; const ay = y[0];
        const bax = x[1] - ax; const bay = y[1] - ay;
        const cax = x[2] - ax; const cay = y[2] - ay;
        const denominator = 2 * (bax * cay - bay * cax);
        const balenSq = bax * bax + bay * bay;
        const calenSq = cax * cax + cay * cay;
        const centerXNum = ax * denominator + cay * balenSq - bay * calenSq;
        const centerYNum = ay * denominator + bax * calenSq - cax * balenSq;
        putI64(&staged, 56, roundRatioAway(centerXNum * COORDINATE_SCALE, denominator));
        putI64(&staged, 64, roundRatioAway(centerYNum * COORDINATE_SCALE, denominator));
        const words = [_]i64{ 3, 0, 1, 3, 1, 2, 3, 2, 0, 3 };
        for (words, 0..) |word, i| putI64(&staged, 72 + 8 * i, word);
    } else {
        const words = [_]i64{ 1, 0, 1, 2 };
        for (words, 0..) |word, i| putI64(&staged, 56 + 8 * i, word);
    }
    const required: usize = if (refine) MAX_OUTPUT_BYTES else 88;
    if (output == null or capacity < required) return -2;
    for (0..required) |i| output[i] = staged[i];
    return @intCast(required);
}
