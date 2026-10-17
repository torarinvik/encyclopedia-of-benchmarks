const MAX_DIMENSION = 8;
const MAX_CELLS = 64;
const MAX_INPUT_LENGTH = 79;
const AxisSolution = struct { first: i64, second: i64, translation: i64 };

fn solveAxis(x: [3]i64, y: [3]i64, target: [3]i64) ?AxisSolution {
    const determinant = x[0] * (y[1] - y[2]) + x[1] * (y[2] - y[0]) + x[2] * (y[0] - y[1]);
    if (determinant == 0) return null;
    const first = target[0] * (y[1] - y[2]) + target[1] * (y[2] - y[0]) + target[2] * (y[0] - y[1]);
    const second = x[0] * (target[1] - target[2]) + x[1] * (target[2] - target[0]) + x[2] * (target[0] - target[1]);
    const translation = x[0] * (y[1] * target[2] - y[2] * target[1]) +
        x[1] * (y[2] * target[0] - y[0] * target[2]) + x[2] * (y[0] * target[1] - y[1] * target[0]);
    if (@rem(first, determinant) != 0 or @rem(second, determinant) != 0 or @rem(translation, determinant) != 0) return null;
    return .{ .first= @divTrunc(first, determinant), .second= @divTrunc(second, determinant), .translation= @divTrunc(translation, determinant) };
}

export fn affine_image_rotation(input_opt: ?[*]const i32, length: usize,
                                output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const rows_value = input[0]; const cols_value = input[1];
    if (rows_value < 1 or rows_value > MAX_DIMENSION or cols_value < 1 or cols_value > MAX_DIMENSION) return -1;
    const rows: usize = @intCast(rows_value); const cols: usize = @intCast(cols_value); const cells = rows * cols;
    if (length != 14 + cells) return -1;
    var pixels = [_]u8{0} ** MAX_CELLS;
    for (0..cells) |i| { if (input[2+i] < 0 or input[2+i] > 255) return -1; pixels[i] = @intCast(input[2+i]); }
    const point_offset = 2 + cells;
    var sx = [_]i64{0} ** 3; var sy = [_]i64{0} ** 3; var dx = [_]i64{0} ** 3; var dy = [_]i64{0} ** 3;
    for (0..3) |i| {
        sx[i] = input[point_offset+2*i]; sy[i] = input[point_offset+2*i+1];
        dx[i] = input[point_offset+6+2*i]; dy[i] = input[point_offset+7+2*i];
        if (sx[i] < -16 or sx[i] > 16 or sy[i] < -16 or sy[i] > 16 or dx[i] < -16 or dx[i] > 16 or dy[i] < -16 or dy[i] > 16) return -1;
    }
    const x_axis = solveAxis(sx, sy, dx) orelse return -1;
    const y_axis = solveAxis(sx, sy, dy) orelse return -1;
    const a=x_axis.first; const b=x_axis.second; const tx=x_axis.translation;
    const c=y_axis.first; const d=y_axis.second; const ty=y_axis.translation;
    if (a < -2 or a > 2 or b < -2 or b > 2 or c < -2 or c > 2 or d < -2 or d > 2 or tx < -16 or tx > 16 or ty < -16 or ty > 16) return -1;
    const determinant=a*d-b*c;
    if (determinant != -1 and determinant != 1) return -1;
    for (0..3) |i| { if (dx[i] != a*sx[i]+b*sy[i]+tx or dy[i] != c*sx[i]+d*sy[i]+ty) return -1; }
    if (output_opt == null or capacity < cells) return -2;
    const output=output_opt.?;
    var written: usize=0;
    for (0..cols) |y| {
        for (0..rows) |x| {
            const px = @as(i64, @intCast(x)) - tx;
            const py = @as(i64, @intCast(y)) - ty;
            const source_x = @divTrunc(d * px - b * py, determinant);
            const source_y = @divTrunc(-c * px + a * py, determinant);
            output[written] = if (source_x >= 0 and source_x < @as(i64, @intCast(cols)) and
                source_y >= 0 and source_y < @as(i64, @intCast(rows)))
                pixels[@as(usize, @intCast(source_y)) * cols + @as(usize, @intCast(source_x))]
            else
                0;
            written += 1;
        }
    }
    return @intCast(cells);
}
