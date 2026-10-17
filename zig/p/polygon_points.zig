const MAX_INPUT_LENGTH: usize = 66;
const INVALID_RESULT: i64 = -1;

fn absI64(value: i64) i64 {
    return if (value < 0) -value else value;
}

fn gcdI64(a: i64, b: i64) i64 {
    var x = a;
    var y = b;
    while (y != 0) {
        const temp = y;
        y = @rem(x, y);
        x = temp;
    }
    return x;
}

fn cross(x1: i64, y1: i64, x2: i64, y2: i64) i64 {
    return x1 * y2 - x2 * y1;
}

export fn polygon_points(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const raw_n = values[0];
    if (raw_n < 3 or raw_n > 32 or length != 1 + 2 * @as(usize, @intCast(raw_n))) return INVALID_RESULT;
    const n: usize = @intCast(raw_n);
    for (0..2 * n) |i| {
        if (values[1 + i] < -1000 or values[1 + i] > 1000) return INVALID_RESULT;
    }

    const origin_x = values[1];
    const origin_y = values[2];
    var doubled_area: i64 = 0;
    for (2..n) |i| {
        const x1 = values[1 + 2 * i] - origin_x;
        const y1 = values[2 + 2 * i] - origin_y;
        const x2 = values[1 + 2 * (i - 1)] - origin_x;
        const y2 = values[2 + 2 * (i - 1)] - origin_y;
        doubled_area += cross(x1, y1, x2, y2);
    }
    const area = absI64(@divTrunc(doubled_area, 2));

    var boundary: i64 = raw_n;
    for (0..n) |i| {
        const next = (i + 1) % n;
        const dx = values[1 + 2 * i] - values[1 + 2 * next];
        const dy = values[2 + 2 * i] - values[2 + 2 * next];
        boundary += absI64(gcdI64(dx, dy)) - 1;
    }
    return area + 1 - @divTrunc(boundary, 2);
}
