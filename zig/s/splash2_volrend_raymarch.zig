const MAX_SIDE: usize = 8;
const MAX_RAYS: usize = 16;
const MAX_SAMPLES: usize = 32;
const MAX_VOXELS: usize = MAX_SIDE * MAX_SIDE * MAX_SIDE;
const MAX_PARSEABLE: usize = 3 + 2 * MAX_VOXELS + 6 * MAX_RAYS + 1;
const MAX_MASKS: usize = 4 * MAX_VOXELS;
const Q8: i64 = 256;
const Q16: i64 = 65536;
const WEIGHT_DEN: i64 = 16777216;
const ALPHA_DEN: i64 = 255 * WEIGHT_DEN;
const COLOR_DEN: i64 = 255 * 255 * WEIGHT_DEN;

fn voxelIndex(side: usize, x: usize, y: usize, z: usize) usize {
    return (z * side + y) * side + x;
}

fn maskIndex(level: usize, x: usize, y: usize, z: usize) usize {
    return ((level * MAX_SIDE + z) * MAX_SIDE + y) * MAX_SIDE + x;
}

fn roundHalfUp(numerator: i64, denominator: i64) i64 {
    return @divTrunc(numerator + @divTrunc(denominator, 2), denominator);
}

fn toByte(q16: i64) u8 {
    return @intCast(@divTrunc(q16 * 255 + @divTrunc(Q16, 2), Q16));
}

fn interpolate(side: usize, alpha: []const u8, gray: []const u8,
    xq: i64, yq: i64, zq: i64) [2]i64 {
    const low = [3]usize{ @intCast(@divTrunc(xq, Q8)), @intCast(@divTrunc(yq, Q8)), @intCast(@divTrunc(zq, Q8)) };
    const frac = [3]i64{ @mod(xq, Q8), @mod(yq, Q8), @mod(zq, Q8) };
    const high = [3]usize{ @min(low[0] + 1, side - 1), @min(low[1] + 1, side - 1), @min(low[2] + 1, side - 1) };
    var opacity_sum: i64 = 0;
    var premul_sum: i64 = 0;
    for (0..2) |dz| {
        const z = if (dz == 0) low[2] else high[2];
        const wz = if (dz == 0) Q8 - frac[2] else frac[2];
        for (0..2) |dy| {
            const y = if (dy == 0) low[1] else high[1];
            const wy = if (dy == 0) Q8 - frac[1] else frac[1];
            for (0..2) |dx| {
                const x = if (dx == 0) low[0] else high[0];
                const wx = if (dx == 0) Q8 - frac[0] else frac[0];
                const at = voxelIndex(side, x, y, z);
                const weight = wx * wy * wz;
                opacity_sum += @as(i64, alpha[at]) * weight;
                premul_sum += @as(i64, alpha[at]) * @as(i64, gray[at]) * weight;
            }
        }
    }
    return .{
        roundHalfUp(opacity_sum * Q16, ALPHA_DEN),
        roundHalfUp(premul_sum * Q16, COLOR_DEN),
    };
}

export fn splash2_volrend_raymarch(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_PARSEABLE) return -1;
    const input = input_opt.?;
    const side_raw = input[0];
    const rays_raw = input[1];
    const samples_raw = input[2];
    if ((side_raw != 2 and side_raw != 4 and side_raw != 8) or rays_raw < 1 or rays_raw > @as(i64, @intCast(MAX_RAYS)) or samples_raw < 1 or samples_raw > @as(i64, @intCast(MAX_SAMPLES))) return -1;
    const side: usize = @intCast(side_raw);
    const ray_count: usize = @intCast(rays_raw);
    const samples: usize = @intCast(samples_raw);
    const voxel_count = side * side * side;
    const ray_start = 3 + 2 * voxel_count;
    if (length != ray_start + 6 * ray_count) return -1;

    var alpha: [MAX_VOXELS]u8 = @splat(0);
    var gray: [MAX_VOXELS]u8 = @splat(0);
    var rays: [MAX_RAYS * 6]i32 = @splat(0);
    for (0..voxel_count) |voxel| {
        const a = input[3 + 2 * voxel];
        const g = input[4 + 2 * voxel];
        if (a < 0 or a > 255 or g < 0 or g > 255) return -1;
        alpha[voxel] = @intCast(a);
        gray[voxel] = @intCast(g);
    }
    const coord_max = (@as(i64, @intCast(side)) - 1) * Q8;
    for (0..ray_count) |ray| {
        const at = ray_start + 6 * ray;
        for (0..3) |axis| {
            const origin = input[at + axis];
            const delta = input[at + axis + 3];
            if (origin < 0 or origin > coord_max or delta < -coord_max or delta > coord_max) return -1;
            rays[6 * ray + axis] = @intCast(origin);
            rays[6 * ray + axis + 3] = @intCast(delta);
        }
        if (samples > 1 and rays[6 * ray + 3] == 0 and rays[6 * ray + 4] == 0 and rays[6 * ray + 5] == 0) return -1;
        for (0..samples) |sample| for (0..3) |axis| {
            const q = @as(i64, rays[6 * ray + axis]) + @as(i64, @intCast(sample)) * @as(i64, rays[6 * ray + axis + 3]);
            if (q < 0 or q > coord_max) return -1;
        };
    }

    const output_bytes = 5 * ray_count;
    if (output_opt == null) return -2;
    if (capacity < output_bytes) return -3;
    const output = output_opt.?;

    var support: [MAX_MASKS]u8 = @splat(0);
    for (0..side) |z| for (0..side) |y| for (0..side) |x| {
        var occupied: u8 = 0;
        for (0..2) |dz| for (0..2) |dy| for (0..2) |dx| {
            const nx = @min(x + dx, side - 1);
            const ny = @min(y + dy, side - 1);
            const nz = @min(z + dz, side - 1);
            if (alpha[voxelIndex(side, nx, ny, nz)] != 0) occupied = 1;
        };
        support[maskIndex(0, x, y, z)] = occupied;
    };
    var levels: usize = 0;
    var dimension = side;
    while (dimension > 1) : (dimension >>= 1) { levels += 1; }
    for (1..levels + 1) |level| {
        const dim = side >> level;
        for (0..dim) |z| for (0..dim) |y| for (0..dim) |x| {
            var occupied: u8 = 0;
            for (0..2) |dz| for (0..2) |dy| for (0..2) |dx| {
                if (support[maskIndex(level - 1, 2 * x + dx, 2 * y + dy, 2 * z + dz)] != 0) occupied = 1;
            };
            support[maskIndex(level, x, y, z)] = occupied;
        };
    }

    for (0..ray_count) |ray| {
        var accumulated_alpha: i64 = 0;
        var accumulated_gray: i64 = 0;
        var used: usize = 0;
        for (0..samples) |sample| {
            used = sample + 1;
            const xq = @as(i64, rays[6 * ray]) + @as(i64, @intCast(sample)) * @as(i64, rays[6 * ray + 3]);
            const yq = @as(i64, rays[6 * ray + 1]) + @as(i64, @intCast(sample)) * @as(i64, rays[6 * ray + 4]);
            const zq = @as(i64, rays[6 * ray + 2]) + @as(i64, @intCast(sample)) * @as(i64, rays[6 * ray + 5]);
            const cx: usize = @intCast(@divTrunc(xq, Q8));
            const cy: usize = @intCast(@divTrunc(yq, Q8));
            const cz: usize = @intCast(@divTrunc(zq, Q8));
            var supported = true;
            var level = @as(isize, @intCast(levels));
            while (level >= 0) : (level -= 1) {
                const l: usize = @intCast(level);
                if (support[maskIndex(l, cx >> l, cy >> l, cz >> l)] == 0) { supported = false; break; }
            }
            if (supported) {
                const values = interpolate(side, alpha[0..], gray[0..], xq, yq, zq);
                const remaining = Q16 - accumulated_alpha;
                accumulated_alpha = @min(Q16, accumulated_alpha + roundHalfUp(remaining * values[0], Q16));
                accumulated_gray = @min(Q16, accumulated_gray + roundHalfUp(remaining * values[1], Q16));
                if (accumulated_alpha == Q16) break;
            }
        }
        const at = 5 * ray;
        const value = toByte(accumulated_gray);
        output[at] = value;
        output[at + 1] = value;
        output[at + 2] = value;
        output[at + 3] = toByte(accumulated_alpha);
        output[at + 4] = @intCast(used);
    }
    return @intCast(output_bytes);
}
