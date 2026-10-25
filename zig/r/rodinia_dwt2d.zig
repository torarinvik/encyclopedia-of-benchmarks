// Rodinia DWT2D (Jiri Matela, Martin Jirman); complete notices in
// benchmarks/r/rodinia_dwt2d/LICENSE.txt. Independent scalar 5/3 lifting port.
const MAX_SIDE: usize = 16;
const MAX_CELLS: usize = MAX_SIDE * MAX_SIDE;
const MAX_INPUT: usize = 3 + MAX_CELLS;
const Line = [MAX_SIDE]i64;

fn transformLine(line: Line, n: usize) Line {
    var result = [_]i64{0} ** MAX_SIDE;
    var detail = [_]i64{0} ** (MAX_SIDE / 2);
    const half = n / 2;
    for (0..half) |j| {
        const even = line[2 * j];
        const right = if (j + 1 < half) line[2 * j + 2] else even;
        detail[j] = line[2 * j + 1] - @divTrunc(even + right, 2);
    }
    result[0] = line[0] + @divTrunc(detail[0] + detail[0] + 2, 4);
    for (1..half) |j| {
        result[j] = line[2 * j] + @divTrunc(detail[j - 1] + detail[j] + 2, 4);
    }
    for (0..half) |j| result[half + j] = detail[j];
    return result;
}

fn putI32Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn rodinia_dwt2d(values: ?[*]const i64, length: usize,
        output: ?[*]u8, capacity: usize) i64 {
    const v = values orelse return -1;
    if (length < 3 or length > MAX_INPUT) return -1;
    const wi = v[0];
    const hi = v[1];
    const li = v[2];
    if (wi < 2 or wi > 16 or hi < 2 or hi > 16 or li < 1 or li > 3) return -1;
    const factor: i64 = @as(i64, 1) << @intCast(li);
    if (wi < factor or hi < factor or @mod(wi, factor) != 0 or @mod(hi, factor) != 0) return -1;
    const width: usize = @intCast(wi);
    const height: usize = @intCast(hi);
    const cells = width * height;
    if (length != 3 + cells) return -1;
    for (0..cells) |i| if (v[3 + i] < 0 or v[3 + i] > 255) return -1;
    const output_bytes = cells * 4;
    const out = output orelse return -2;
    if (capacity < output_bytes) return -2;

    var plane = [_]i64{0} ** MAX_CELLS;
    var vertical = [_]i64{0} ** MAX_CELLS;
    var next = [_]i64{0} ** MAX_CELLS;
    var ordered = [_]i64{0} ** MAX_CELLS;
    for (0..cells) |i| plane[i] = v[3 + i] - 128;
    var active_width = width;
    var active_height = height;
    for (0..@as(usize, @intCast(li))) |_| {
        for (0..active_width) |x| {
            var line = [_]i64{0} ** MAX_SIDE;
            for (0..active_height) |y| line[y] = plane[y * width + x];
            const transformed = transformLine(line, active_height);
            for (0..active_height) |y| vertical[y * width + x] = transformed[y];
        }
        for (0..active_height) |y| {
            var line = [_]i64{0} ** MAX_SIDE;
            for (0..active_width) |x| line[x] = vertical[y * width + x];
            const transformed = transformLine(line, active_width);
            for (0..active_width) |x| next[y * width + x] = transformed[x];
        }
        for (0..active_height) |y| {
            for (0..active_width) |x| plane[y * width + x] = next[y * width + x];
        }
        active_width /= 2;
        active_height /= 2;
    }
    var output_index: usize = 0;
    var stage = @as(usize, @intCast(li));
    while (stage > 0) {
        stage -= 1;
        const stage_width = width >> @intCast(stage);
        const stage_height = height >> @intCast(stage);
        const half_width = stage_width / 2;
        const half_height = stage_height / 2;
        if (stage == @as(usize, @intCast(li - 1))) {
            for (0..half_height) |y| {
                for (0..half_width) |x| { ordered[output_index] = plane[y * width + x]; output_index += 1; }
            }
        }
        for (0..half_height) |y| {
            for (half_width..stage_width) |x| { ordered[output_index] = plane[y * width + x]; output_index += 1; }
        }
        for (half_height..stage_height) |y| {
            for (0..half_width) |x| { ordered[output_index] = plane[y * width + x]; output_index += 1; }
        }
        for (half_height..stage_height) |y| {
            for (half_width..stage_width) |x| { ordered[output_index] = plane[y * width + x]; output_index += 1; }
        }
    }
    for (0..cells) |i| putI32Le(out, 4 * i, ordered[i]);
    return @intCast(output_bytes);
}
