const MAX_DIM: usize = 4;
const MAX_ATOMS: usize = 4;
const MAX_INPUT: usize = 25;
const MAX_GRID: usize = 64;
const INV_CELL_LENGTH: f32 = 0.25;

const Atom = struct { x: f32, y: f32, z: f32, q: f32 };

fn decodeComponent(raw: i64) f32 {
    return @as(f32, @floatFromInt(raw)) / 1_000_000.0;
}

fn quantizeQ(value: f32) i32 {
    const scaled = value * 1_000.0;
    const magnitude = @abs(scaled);
    var whole: i32 = @intFromFloat(magnitude);
    if (magnitude - @as(f32, @floatFromInt(whole)) >= 0.5) whole += 1;
    return if (scaled < 0.0) -whole else whole;
}

fn writeI32Le(output: [*c]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    output[offset] = @truncate(bits);
    output[offset + 1] = @truncate(bits >> 8);
    output[offset + 2] = @truncate(bits >> 16);
    output[offset + 3] = @truncate(bits >> 24);
}

pub export fn parboil_cutcp(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 13 or input_length > MAX_INPUT) return -1;
    if (input[0] < 2 or input[0] > 4 or input[1] < 2 or input[1] > 4
            or input[2] < 2 or input[2] > 4 or input[3] < 1 or input[3] > 4) return -1;
    const nx: usize = @intCast(input[0]);
    const ny: usize = @intCast(input[1]);
    const nz: usize = @intCast(input[2]);
    const atom_count: usize = @intCast(input[3]);
    if (input_length != 9 + 4 * atom_count) return -1;
    const xlo_raw = input[4];
    const ylo_raw = input[5];
    const zlo_raw = input[6];
    const spacing_raw = input[7];
    const cutoff_raw = input[8];
    if (xlo_raw < -16_000_000 or xlo_raw > 16_000_000
            or ylo_raw < -16_000_000 or ylo_raw > 16_000_000
            or zlo_raw < -16_000_000 or zlo_raw > 16_000_000
            or @rem(xlo_raw, 1_000_000) != 0 or @rem(ylo_raw, 1_000_000) != 0
            or @rem(zlo_raw, 1_000_000) != 0
            or spacing_raw < 1_000_000 or spacing_raw > 4_000_000
            or @rem(spacing_raw, 1_000_000) != 0
            or cutoff_raw < 250_000 or cutoff_raw > 4_000_000) return -1;
    for (0..atom_count) |n| {
        const offset = 9 + 4 * n;
        if (input[offset] < 0 or input[offset] >= @as(i64, @intCast(nx - 1))
                or input[offset + 1] < 0 or input[offset + 1] >= @as(i64, @intCast(ny - 1))
                or input[offset + 2] < 0 or input[offset + 2] >= @as(i64, @intCast(nz - 1))
                or input[offset + 3] < -1_000_000 or input[offset + 3] > 1_000_000) return -1;
    }
    const points = nx * ny * nz;
    const output_bytes = 4 * points;
    if (output == null or output_capacity < output_bytes) return -2;

    const xlo = decodeComponent(xlo_raw);
    const ylo = decodeComponent(ylo_raw);
    const zlo = decodeComponent(zlo_raw);
    const spacing = decodeComponent(spacing_raw);
    const cutoff = decodeComponent(cutoff_raw);
    const half_spacing = spacing * 0.5;
    var atoms = [_]Atom{.{ .x = 0, .y = 0, .z = 0, .q = 0 }} ** MAX_ATOMS;
    for (0..atom_count) |n| {
        const offset = 9 + 4 * n;
        const ix: usize = @intCast(input[offset]);
        const iy: usize = @intCast(input[offset + 1]);
        const iz: usize = @intCast(input[offset + 2]);
        atoms[n] = .{
            .x = xlo + (@as(f32, @floatFromInt(ix)) * spacing + half_spacing),
            .y = ylo + (@as(f32, @floatFromInt(iy)) * spacing + half_spacing),
            .z = zlo + (@as(f32, @floatFromInt(iz)) * spacing + half_spacing),
            .q = decodeComponent(input[offset + 3]),
        };
    }
    var min_x = atoms[0].x;
    var max_x = atoms[0].x;
    var min_y = atoms[0].y;
    var max_y = atoms[0].y;
    var min_z = atoms[0].z;
    var max_z = atoms[0].z;
    for (1..atom_count) |n| {
        if (atoms[n].x < min_x) min_x = atoms[n].x;
        if (atoms[n].x > max_x) max_x = atoms[n].x;
        if (atoms[n].y < min_y) min_y = atoms[n].y;
        if (atoms[n].y > max_y) max_y = atoms[n].y;
        if (atoms[n].z < min_z) min_z = atoms[n].z;
        if (atoms[n].z > max_z) max_z = atoms[n].z;
    }
    const nx_cell: usize = @as(usize, @intFromFloat(@floor((max_x - min_x) * INV_CELL_LENGTH))) + 1;
    const ny_cell: usize = @as(usize, @intFromFloat(@floor((max_y - min_y) * INV_CELL_LENGTH))) + 1;
    const nz_cell: usize = @as(usize, @intFromFloat(@floor((max_z - min_z) * INV_CELL_LENGTH))) + 1;
    const cell_count = nx_cell * ny_cell * nz_cell;
    var first = [_]isize{-1} ** MAX_GRID;
    var next = [_]isize{-1} ** MAX_ATOMS;
    for (0..atom_count) |n| {
        if (atoms[n].q == 0) continue;
        const i: usize = @intFromFloat(@floor((atoms[n].x - min_x) * INV_CELL_LENGTH));
        const j: usize = @intFromFloat(@floor((atoms[n].y - min_y) * INV_CELL_LENGTH));
        const k: usize = @intFromFloat(@floor((atoms[n].z - min_z) * INV_CELL_LENGTH));
        const cell = (k * ny_cell + j) * nx_cell + i;
        next[n] = first[cell];
        first[cell] = @intCast(n);
    }

    const cutoff_squared = cutoff * cutoff;
    const inv_cutoff_squared = 1.0 / cutoff_squared;
    const inv_spacing = 1.0 / spacing;
    const radius: isize = @as(isize, @intFromFloat(@ceil(cutoff * inv_spacing))) - 1;
    var grid = [_]f32{0} ** MAX_GRID;
    for (0..cell_count) |cell| {
        var n = first[cell];
        while (n != -1) {
            const atom_index: usize = @intCast(n);
            const x = atoms[atom_index].x - xlo;
            const y = atoms[atom_index].y - ylo;
            const z = atoms[atom_index].z - zlo;
            const q = atoms[atom_index].q;
            const ic: isize = @intFromFloat(x * inv_spacing);
            const jc: isize = @intFromFloat(y * inv_spacing);
            const kc: isize = @intFromFloat(z * inv_spacing);
            var ia = ic - radius;
            var ib = ic + radius + 1;
            var ja = jc - radius;
            var jb = jc + radius + 1;
            var ka = kc - radius;
            var kb = kc + radius + 1;
            if (ia < 0) ia = 0;
            if (ib >= @as(isize, @intCast(nx))) ib = @intCast(nx - 1);
            if (ja < 0) ja = 0;
            if (jb >= @as(isize, @intCast(ny))) jb = @intCast(ny - 1);
            if (ka < 0) ka = 0;
            if (kb >= @as(isize, @intCast(nz))) kb = @intCast(nz - 1);
            const xstart = @as(f32, @floatFromInt(ia)) * spacing - x;
            const ystart = @as(f32, @floatFromInt(ja)) * spacing - y;
            var dz = @as(f32, @floatFromInt(ka)) * spacing - z;
            var k = ka;
            while (k <= kb) : (k += 1) {
                const koff: usize = @intCast(k * @as(isize, @intCast(ny)));
                const dz2 = dz * dz;
                var dy = ystart;
                var j = ja;
                while (j <= jb) : (j += 1) {
                    const jkoff: usize = @intCast((@as(isize, @intCast(koff)) + j) * @as(isize, @intCast(nx)));
                    const dydz2 = dy * dy + dz2;
                    if (dydz2 < cutoff_squared) {
                        var dx = xstart;
                        var i = ia;
                        while (i <= ib) : (i += 1) {
                            const r2 = dx * dx + dydz2;
                            if (r2 < cutoff_squared) {
                                const s = 1.0 - r2 * inv_cutoff_squared;
                                const reciprocal_r = 1.0 / @sqrt(r2);
                                var energy = q * reciprocal_r;
                                energy *= s;
                                energy *= s;
                                grid[jkoff + @as(usize, @intCast(i))] += energy;
                            }
                            dx += spacing;
                        }
                    }
                    dy += spacing;
                }
                dz += spacing;
            }
            n = next[atom_index];
        }
    }
    for (0..points) |point| writeI32Le(output, 4 * point, quantizeQ(grid[point]));
    return @intCast(output_bytes);
}
