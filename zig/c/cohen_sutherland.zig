/// Selected coordinate or acceptance flag from Cohen-Sutherland clipping.
const INVALID_RESULT: f64 = -1.0e300;
const SCALE: f64 = 1_000_000.0;
const MAX_COORDINATE_MICRO: i64 = 1_000_000_000;
const INSIDE: i32 = 0;
const LEFT: i32 = 1;
const RIGHT: i32 = 2;
const BOTTOM: i32 = 4;
const TOP: i32 = 8;

fn regionCode(x: f64, y: f64, x_min: f64, y_min: f64, x_max: f64, y_max: f64) i32 {
    var code: i32 = INSIDE;
    if (x < x_min) code |= LEFT else if (x > x_max) code |= RIGHT;
    if (y < y_min) code |= BOTTOM else if (y > y_max) code |= TOP;
    return code;
}

export fn cohen_sutherland(values: ?[*]const i64, length: usize) f64 {
    if (values == null or length != 9) return INVALID_RESULT;
    const input = values.?;
    const selector = input[0];
    if (selector < 0 or selector > 4) return INVALID_RESULT;
    for (1..9) |i| {
        if (input[i] < -MAX_COORDINATE_MICRO or input[i] > MAX_COORDINATE_MICRO)
            return INVALID_RESULT;
    }
    const x_min = @as(f64, @floatFromInt(input[1])) / SCALE;
    const y_min = @as(f64, @floatFromInt(input[2])) / SCALE;
    const x_max = @as(f64, @floatFromInt(input[3])) / SCALE;
    const y_max = @as(f64, @floatFromInt(input[4])) / SCALE;
    if (x_min >= x_max or y_min >= y_max) return INVALID_RESULT;
    var x1 = @as(f64, @floatFromInt(input[5])) / SCALE;
    var y1 = @as(f64, @floatFromInt(input[6])) / SCALE;
    var x2 = @as(f64, @floatFromInt(input[7])) / SCALE;
    var y2 = @as(f64, @floatFromInt(input[8])) / SCALE;
    var code1 = regionCode(x1, y1, x_min, y_min, x_max, y_max);
    var code2 = regionCode(x2, y2, x_min, y_min, x_max, y_max);
    var accepted = false;
    while (true) {
        if (code1 == INSIDE and code2 == INSIDE) {
            accepted = true;
            break;
        }
        if ((code1 & code2) != 0) break;
        const code_out = if (code1 != INSIDE) code1 else code2;
        var x: f64 = undefined;
        var y: f64 = undefined;
        if ((code_out & TOP) != 0) {
            x = x1 + (x2 - x1) * (y_max - y1) / (y2 - y1);
            y = y_max;
        } else if ((code_out & BOTTOM) != 0) {
            x = x1 + (x2 - x1) * (y_min - y1) / (y2 - y1);
            y = y_min;
        } else if ((code_out & RIGHT) != 0) {
            y = y1 + (y2 - y1) * (x_max - x1) / (x2 - x1);
            x = x_max;
        } else {
            y = y1 + (y2 - y1) * (x_min - x1) / (x2 - x1);
            x = x_min;
        }
        if (code_out == code1) {
            x1 = x;
            y1 = y;
            code1 = regionCode(x1, y1, x_min, y_min, x_max, y_max);
        } else {
            x2 = x;
            y2 = y;
            code2 = regionCode(x2, y2, x_min, y_min, x_max, y_max);
        }
    }
    if (selector == 4) return if (accepted) 1.0 else 0.0;
    if (!accepted) return INVALID_RESULT;
    return switch (selector) {
        0 => x1,
        1 => y1,
        2 => x2,
        else => y2,
    };
}
