const BIN_SIDE: usize = 32;
const HISTOGRAM_SIZE: usize = BIN_SIDE * BIN_SIDE * BIN_SIDE;
const MAX_PALETTE: usize = 8;
const MAX_PIXELS: usize = 16;
const MAX_INPUT_LENGTH: usize = 50;

const ColorBox = struct {
    rmin: usize,
    rmax: usize,
    gmin: usize,
    gmax: usize,
    bmin: usize,
    bmax: usize,
    total: usize,
};

fn histAt(histogram: *const [HISTOGRAM_SIZE]i32, r: usize, g: usize, b: usize) i32 {
    return histogram[(r * BIN_SIDE + g) * BIN_SIDE + b];
}

fn shrinkBox(histogram: *const [HISTOGRAM_SIZE]i32, box: *ColorBox) void {
    var rmin: usize = BIN_SIDE;
    var gmin: usize = BIN_SIDE;
    var bmin: usize = BIN_SIDE;
    var rmax: usize = 0;
    var gmax: usize = 0;
    var bmax: usize = 0;
    var r = box.rmin;
    while (r <= box.rmax) : (r += 1) {
        var g = box.gmin;
        while (g <= box.gmax) : (g += 1) {
            var b = box.bmin;
            while (b <= box.bmax) : (b += 1) {
                if (histAt(histogram, r, g, b) != 0) {
                    rmin = @min(rmin, r);
                    rmax = @max(rmax, r);
                    gmin = @min(gmin, g);
                    gmax = @max(gmax, g);
                    bmin = @min(bmin, b);
                    bmax = @max(bmax, b);
                }
            }
        }
    }
    box.rmin = rmin;
    box.rmax = rmax;
    box.gmin = gmin;
    box.gmax = gmax;
    box.bmin = bmin;
    box.bmax = bmax;
}

fn largestBox(boxes: *const [MAX_PALETTE]ColorBox, count: usize) ?usize {
    var selected: ?usize = null;
    var largest_total: usize = 0;
    for (0..count) |i| {
        const b = boxes[i];
        if ((b.rmax > b.rmin or b.gmax > b.gmin or b.bmax > b.bmin) and
            (selected == null or b.total > largest_total))
        {
            selected = i;
            largest_total = b.total;
        }
    }
    return selected;
}

fn splitBox(histogram: *const [HISTOGRAM_SIZE]i32, boxes: *[MAX_PALETTE]ColorBox, count: *usize, selected: usize) void {
    var upper = boxes[selected];
    const r_span = upper.rmax - upper.rmin;
    const g_span = upper.gmax - upper.gmin;
    const b_span = upper.bmax - upper.bmin;
    const axis: usize = if (r_span >= g_span and r_span >= b_span) 0 else if (g_span >= b_span) 1 else 2;
    const first = if (axis == 0) upper.rmin else if (axis == 1) upper.gmin else upper.bmin;
    const last = if (axis == 0) upper.rmax else if (axis == 1) upper.gmax else upper.bmax;
    var along = [_]i32{0} ** BIN_SIDE;
    var r = upper.rmin;
    while (r <= upper.rmax) : (r += 1) {
        var g = upper.gmin;
        while (g <= upper.gmax) : (g += 1) {
            var b = upper.bmin;
            while (b <= upper.bmax) : (b += 1) {
                const coordinate = if (axis == 0) r else if (axis == 1) g else b;
                along[coordinate] += histAt(histogram, r, g, b);
            }
        }
    }
    const median = upper.total / 2;
    var accumulated: usize = 0;
    var split = first;
    while (split <= last) : (split += 1) {
        accumulated += @as(usize, @intCast(along[split]));
        if (accumulated >= median) break;
    }
    if (split == first) split += 1;

    var lower = upper;
    var lower_total: usize = 0;
    var upper_total: usize = 0;
    var bin = first;
    while (bin < split) : (bin += 1) lower_total += @as(usize, @intCast(along[bin]));
    bin = split;
    while (bin <= last) : (bin += 1) upper_total += @as(usize, @intCast(along[bin]));
    lower.total = lower_total;
    upper.total = upper_total;
    if (axis == 0) {
        lower.rmax = split - 1;
        upper.rmin = split;
    } else if (axis == 1) {
        lower.gmax = split - 1;
        upper.gmin = split;
    } else {
        lower.bmax = split - 1;
        upper.bmin = split;
    }
    shrinkBox(histogram, &lower);
    shrinkBox(histogram, &upper);
    boxes[selected] = upper;
    var i = count.*;
    while (i > 0) : (i -= 1) boxes[i] = boxes[i - 1];
    boxes[0] = lower;
    count.* += 1;
}

pub export fn cbench_consumer_tiffmedian(
    input: [*c]const i64,
    input_length: usize,
    output: [*c]u8,
    output_capacity: usize,
) i64 {
    if (input == null or input_length < 5 or input_length > MAX_INPUT_LENGTH) return -1;
    const palette_value = input[0];
    const pixel_value = input[1];
    if (palette_value < 1 or palette_value > MAX_PALETTE or pixel_value < 1 or pixel_value > MAX_PIXELS) return -1;
    const palette_limit: usize = @intCast(palette_value);
    const pixel_count: usize = @intCast(pixel_value);
    if (input_length != 2 + 3 * pixel_count) return -1;
    for (0..3 * pixel_count) |i| {
        const value = input[i + 2];
        if (value < 0 or value > 255) return -1;
    }

    var histogram = [_]i32{0} ** HISTOGRAM_SIZE;
    var boxes = [_]ColorBox{.{
        .rmin = 0, .rmax = 0, .gmin = 0, .gmax = 0,
        .bmin = 0, .bmax = 0, .total = 0,
    }} ** MAX_PALETTE;
    var rmin: usize = BIN_SIDE;
    var gmin: usize = BIN_SIDE;
    var bmin: usize = BIN_SIDE;
    var rmax: usize = 0;
    var gmax: usize = 0;
    var bmax: usize = 0;
    for (0..pixel_count) |p| {
        const r: usize = @intCast(input[2 + 3 * p] >> 3);
        const g: usize = @intCast(input[3 + 3 * p] >> 3);
        const b: usize = @intCast(input[4 + 3 * p] >> 3);
        histogram[(r * BIN_SIDE + g) * BIN_SIDE + b] += 1;
        rmin = @min(rmin, r); rmax = @max(rmax, r);
        gmin = @min(gmin, g); gmax = @max(gmax, g);
        bmin = @min(bmin, b); bmax = @max(bmax, b);
    }
    boxes[0] = .{ .rmin = rmin, .rmax = rmax, .gmin = gmin, .gmax = gmax,
        .bmin = bmin, .bmax = bmax, .total = pixel_count };
    var box_count: usize = 1;
    while (box_count < palette_limit) {
        const selected = largestBox(&boxes, box_count) orelse break;
        splitBox(&histogram, &boxes, &box_count, selected);
    }
    const output_bytes = 1 + 3 * box_count;
    if (output == null or output_capacity < output_bytes) return -2;
    output[0] = @intCast(box_count);
    for (0..box_count) |i| {
        output[1 + 3 * i] = @intCast((boxes[i].rmin + boxes[i].rmax) * 4);
        output[2 + 3 * i] = @intCast((boxes[i].gmin + boxes[i].gmax) * 4);
        output[3 + 3 * i] = @intCast((boxes[i].bmin + boxes[i].bmax) * 4);
    }
    return @intCast(output_bytes);
}
