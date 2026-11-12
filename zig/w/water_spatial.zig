const MAX_MOLECULES: usize = 64;
const MAX_GRID_SIDE: usize = 8;
const MAX_CELLS: usize = 512;
const MAX_INPUT_LENGTH: usize = 4 + 4 * MAX_MOLECULES;
const SCALE: i64 = 1_000_000;

fn truncDiv(numerator: i64, denominator: i64) i64 {
    return if (numerator < 0) -((-numerator) / denominator) else numerator / denominator;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn water_spatial(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const count_value = input[0];
    const grid_value = input[1];
    const cutoff = input[2];
    if (count_value < 0 or count_value > MAX_MOLECULES
            or grid_value < 1 or grid_value > MAX_GRID_SIDE
            or cutoff < 1 or cutoff > 4) return -1;
    const count: usize = @intCast(count_value);
    const grid: usize = @intCast(grid_value);
    if (length != 3 + 4 * count) return -1;
    const extent: i64 = @as(i64, @intCast(grid)) * cutoff;
    for (0..count) |index| {
        const base = 3 + 4 * index;
        if (input[base] < 0 or input[base] >= extent
                or input[base + 1] < 0 or input[base + 1] >= extent
                or input[base + 2] < 0 or input[base + 2] >= extent
                or input[base + 3] < -4 or input[base + 3] > 4) return -1;
    }
    const output_bytes = 8 * (3 * count + 2);
    if (output_opt == null or capacity < output_bytes) return -2;

    var head: [MAX_CELLS]i64 = @splat(-1);
    var next: [MAX_MOLECULES]i64 = @splat(0);
    var force_x: [MAX_MOLECULES]i64 = @splat(0);
    var force_y: [MAX_MOLECULES]i64 = @splat(0);
    var force_z: [MAX_MOLECULES]i64 = @splat(0);
    for (0..count) |index| {
        const base = 3 + 4 * index;
        const cx: usize = @intCast(@divTrunc(input[base], cutoff));
        const cy: usize = @intCast(@divTrunc(input[base + 1], cutoff));
        const cz: usize = @intCast(@divTrunc(input[base + 2], cutoff));
        const cell = cx + grid * (cy + grid * cz);
        next[index] = head[cell];
        head[cell] = @intCast(index);
    }

    var energy: i64 = 0;
    var pairs: i64 = 0;
    const cutoff_squared = cutoff * cutoff;
    for (0..count) |index| {
        const base_i = 3 + 4 * index;
        const cx: i64 = @divTrunc(input[base_i], cutoff);
        const cy: i64 = @divTrunc(input[base_i + 1], cutoff);
        const cz: i64 = @divTrunc(input[base_i + 2], cutoff);
        for (0..3) |oz_value| {
            const nz = cz + @as(i64, @intCast(oz_value)) - 1;
            if (nz < 0 or nz >= @as(i64, @intCast(grid))) continue;
            for (0..3) |oy_value| {
                const ny = cy + @as(i64, @intCast(oy_value)) - 1;
                if (ny < 0 or ny >= @as(i64, @intCast(grid))) continue;
                for (0..3) |ox_value| {
                    const nx = cx + @as(i64, @intCast(ox_value)) - 1;
                    if (nx < 0 or nx >= @as(i64, @intCast(grid))) continue;
                    const cell = @as(usize, @intCast(nx)) + grid *
                        (@as(usize, @intCast(ny)) + grid * @as(usize, @intCast(nz)));
                    var candidate = head[cell];
                    while (candidate >= 0) {
                        const other: usize = @intCast(candidate);
                        if (other > index) {
                            const base_j = 3 + 4 * other;
                            const dx = input[base_j] - input[base_i];
                            const dy = input[base_j + 1] - input[base_i + 1];
                            const dz = input[base_j + 2] - input[base_i + 2];
                            const r2 = dx * dx + dy * dy + dz * dz;
                            if (r2 < cutoff_squared) {
                                const product = input[base_i + 3] * input[base_j + 3];
                                energy += truncDiv(product * (cutoff_squared - r2) * SCALE,
                                    (1 + r2) * (1 + cutoff_squared));
                                const denominator = (1 + r2) * (1 + r2);
                                const px = truncDiv(-2 * product * dx * SCALE, denominator);
                                const py = truncDiv(-2 * product * dy * SCALE, denominator);
                                const pz = truncDiv(-2 * product * dz * SCALE, denominator);
                                force_x[index] += px; force_x[other] -= px;
                                force_y[index] += py; force_y[other] -= py;
                                force_z[index] += pz; force_z[other] -= pz;
                                pairs += 1;
                            }
                        }
                        candidate = next[other];
                    }
                }
            }
        }
    }
    const output = output_opt.?;
    for (0..count) |index| {
        storeI64Le(output, 8 * (3 * index), force_x[index]);
        storeI64Le(output, 8 * (3 * index + 1), force_y[index]);
        storeI64Le(output, 8 * (3 * index + 2), force_z[index]);
    }
    storeI64Le(output, 8 * (3 * count), energy);
    storeI64Le(output, 8 * (3 * count + 1), pairs);
    return @intCast(output_bytes);
}
