const SAD_RANGE: i32 = 16;
const SAD_DIM: usize = 33;
const SAD_POS: usize = 1089;
const SAD_PAD: usize = 1092;
const SAD_SLOTS: usize = 44772;
const TYPE_COUNT = [_]usize{ 0, 1, 2, 2, 4, 8, 8, 16 };
const TYPE_OFFSET = [_]usize{ 0, 0, 1, 3, 5, 9, 17, 25 };

fn pixel(values: [*c]const i64, image: usize, y: usize, x: usize) i32 {
    const packed: u32 = @intCast(values[image * 64 + y * 4 + x / 4]);
    return @intCast((packed >> @intCast((x % 4) * 8)) & 255);
}

export fn parboil_sad(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 128) return -1;
    for (0..128) |i| if (values[i] < 0 or values[i] > 4294967295) return -1;

    var sads = [_]u16{0} ** SAD_SLOTS;
    var py: i32 = -SAD_RANGE;
    while (py <= SAD_RANGE) : (py += 1) {
        var px: i32 = -SAD_RANGE;
        while (px <= SAD_RANGE) : (px += 1) {
            for (0..4) |by| {
                for (0..4) |bx| {
                    const base = (TYPE_OFFSET[7] + by * 4 + bx) * SAD_PAD;
                    const pos: usize = @intCast((py + SAD_RANGE) * 33 + px + SAD_RANGE);
                    var sad: u32 = 0;
                    for (0..4) |y| {
                        for (0..4) |x| {
                            const fy = by * 4 + y;
                            const fx = bx * 4 + x;
                            const ry: usize = @intCast(@max(0, @min(15, @as(i32, @intCast(fy)) + py)));
                            const rx: usize = @intCast(@max(0, @min(15, @as(i32, @intCast(fx)) + px)));
                            const delta = pixel(values, 0, fy, fx) - pixel(values, 1, ry, rx);
                            sad += @intCast(if (delta < 0) -delta else delta);
                        }
                    }
                    sads[base + pos] = @intCast(sad);
                }
            }
        }
    }

    // Source larger_sads hierarchy: types 6, 5, 4, 3, 2, then 1.
    for (0..2) |by| {
        for (0..4) |bx| {
            const dst = TYPE_OFFSET[6] + 4 * by + bx;
            const src = TYPE_OFFSET[7] + 8 * by + bx;
            for (0..SAD_POS) |p| sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+4)*SAD_PAD+p];
        }
    }
    for (0..4) |by| {
        for (0..2) |bx| {
            const dst = TYPE_OFFSET[5] + 2 * by + bx;
            const src = TYPE_OFFSET[7] + 4 * by + 2 * bx;
            for (0..SAD_POS) |p| sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+1)*SAD_PAD+p];
        }
    }
    for (0..2) |by| {
        for (0..2) |bx| {
            const dst = TYPE_OFFSET[4] + 2 * by + bx;
            const src = TYPE_OFFSET[5] + 4 * by + bx;
            for (0..SAD_POS) |p| sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+2)*SAD_PAD+p];
        }
    }
    for (0..2) |bx| {
        const dst = TYPE_OFFSET[3] + bx;
        const src = TYPE_OFFSET[4] + bx;
        for (0..SAD_POS) |p| sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+2)*SAD_PAD+p];
    }
    for (0..2) |by| {
        const dst = TYPE_OFFSET[2] + by;
        const src = TYPE_OFFSET[4] + 2 * by;
        for (0..SAD_POS) |p| sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+1)*SAD_PAD+p];
    }
    for (0..SAD_POS) |p| sads[TYPE_OFFSET[1]*SAD_PAD+p] = sads[TYPE_OFFSET[2]*SAD_PAD+p] + sads[(TYPE_OFFSET[2]+1)*SAD_PAD+p];

    var checksum: i64 = 0;
    for (1..8) |kind| {
        for (0..TYPE_COUNT[kind]) |block| {
            for (0..SAD_POS) |p| checksum += @as(i64, @intCast(sads[(TYPE_OFFSET[kind]+block)*SAD_PAD+p]));
        }
    }
    return checksum;
}
