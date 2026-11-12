const std = @import("std");

const MAX_POINTS: usize = 32;
const MAX_MICRO: i64 = 1_000_000_000;
const SCALE: f64 = 1_000_000.0;

fn writeF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
    }
}

fn solve5(d: *const [25]f64, rhs: [5]f64) ?[5]f64 {
    var a = d.*;
    var b = rhs;
    for (0..5) |pivot| {
        const diagonal = a[pivot * 5 + pivot];
        if (!(diagonal > 0.0) or !std.math.isFinite(diagonal)) return null;
        for (pivot + 1..5) |row| {
            const factor = a[row * 5 + pivot] / diagonal;
            for (pivot + 1..5) |column| {
                a[row * 5 + column] -= factor * a[pivot * 5 + column];
            }
            b[row] -= factor * b[pivot];
        }
    }
    var result: [5]f64 = @splat(0.0);
    for (0..5) |back| {
        const row = 4 - back;
        var tail: f64 = 0.0;
        for (row + 1..5) |column| {
            tail += a[row * 5 + column] * result[column];
        }
        result[row] = (b[row] - tail) / a[row * 5 + row];
    }
    return result;
}

fn apply(nx: usize, ny: usize, nz: usize, d: *const [25]f64, c: *const [3]f64,
         x: *const [160]f64, out: *[160]f64) void {
    const points = nx * ny * nz;
    const nxy = nx * ny;
    for (0..points) |point| {
        const ix = point % nx;
        const iy = (point / nx) % ny;
        const iz = point / nxy;
        for (0..5) |row| {
            var total: f64 = 0.0;
            for (0..5) |column| {
                total += d[row * 5 + column] * x[point * 5 + column];
            }
            if (ix > 0) total += c[0] * x[(point - 1) * 5 + row];
            if (ix + 1 < nx) total += c[0] * x[(point + 1) * 5 + row];
            if (iy > 0) total += c[1] * x[(point - nx) * 5 + row];
            if (iy + 1 < ny) total += c[1] * x[(point + nx) * 5 + row];
            if (iz > 0) total += c[2] * x[(point - nxy) * 5 + row];
            if (iz + 1 < nz) total += c[2] * x[(point + nxy) * 5 + row];
            out[point * 5 + row] = total;
        }
    }
}

fn valid(v: [*]const i64, length: usize) ?[4]usize {
    if (length < 42 or length > 352 or v[0] < 1 or v[0] > 4 or v[1] < 1 or v[1] > 4 or
        v[2] < 1 or v[2] > 4 or v[3] < 1 or v[3] > 8) return null;
    const nx: usize = @intCast(v[0]);
    const ny: usize = @intCast(v[1]);
    const nz: usize = @intCast(v[2]);
    const sweeps: usize = @intCast(v[3]);
    const points = nx * ny * nz;
    if (points > MAX_POINTS or length != 32 + 10 * points) return null;
    for (4..length) |index| {
        if (v[index] < -MAX_MICRO or v[index] > MAX_MICRO) return null;
    }
    for (0..5) |row| {
        const diagonal = v[4 + row * 5 + row];
        var off_sum: i64 = 0;
        for (0..5) |column| {
            const entry = v[4 + row * 5 + column];
            if (entry != v[4 + column * 5 + row]) return null;
            if (row != column) off_sum += if (entry < 0) -entry else entry;
        }
        if (nx > 1) off_sum += 2 * (if (v[29] < 0) -v[29] else v[29]);
        if (ny > 1) off_sum += 2 * (if (v[30] < 0) -v[30] else v[30]);
        if (nz > 1) off_sum += 2 * (if (v[31] < 0) -v[31] else v[31]);
        if (diagonal <= 0 or diagonal <= off_sum) return null;
    }
    return .{ nx, ny, nz, sweeps };
}

export fn npb_lu_block_ssor(input: ?[*]const i64, length: usize,
                            output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    const shape = valid(values, length) orelse return -1;
    const nx = shape[0];
    const ny = shape[1];
    const nz = shape[2];
    const sweeps = shape[3];
    const points = nx * ny * nz;
    const count = points * 5;
    const output_bytes = 8 * (sweeps + count);
    const out = output orelse return -2;
    if (capacity < output_bytes) return -2;

    var d: [25]f64 = undefined;
    var c: [3]f64 = undefined;
    var x: [160]f64 = @splat(0.0);
    var rhs: [160]f64 = @splat(0.0);
    var applied: [160]f64 = @splat(0.0);
    var residual: [160]f64 = @splat(0.0);
    var forward: [160]f64 = @splat(0.0);
    var correction: [160]f64 = @splat(0.0);
    for (0..25) |index| {
        d[index] = @as(f64, @floatFromInt(values[4 + index])) / SCALE;
    }
    for (0..3) |axis| {
        c[axis] = @as(f64, @floatFromInt(values[29 + axis])) / SCALE;
    }
    for (0..count) |index| {
        rhs[index] = @as(f64, @floatFromInt(values[32 + index])) / SCALE;
        x[index] = @as(f64, @floatFromInt(values[32 + count + index])) / SCALE;
    }
    const nxy = nx * ny;
    for (0..sweeps) |sweep| {
        apply(nx, ny, nz, &d, &c, &x, &applied);
        for (0..count) |index| {
            residual[index] = rhs[index] - applied[index];
        }
        for (0..points) |point| {
            const ix = point % nx;
            const iy = (point / nx) % ny;
            const iz = point / nxy;
            var local: [5]f64 = @splat(0.0);
            for (0..5) |row| {
                local[row] = residual[point * 5 + row];
            }
            if (ix > 0) {
                for (0..5) |row| {
                    local[row] -= c[0] * forward[(point - 1) * 5 + row];
                }
            }
            if (iy > 0) {
                for (0..5) |row| {
                    local[row] -= c[1] * forward[(point - nx) * 5 + row];
                }
            }
            if (iz > 0) {
                for (0..5) |row| {
                    local[row] -= c[2] * forward[(point - nxy) * 5 + row];
                }
            }
            const solved = solve5(&d, local) orelse return -1;
            for (0..5) |row| {
                forward[point * 5 + row] = solved[row];
            }
        }
        for (0..points) |back| {
            const point = points - 1 - back;
            const ix = point % nx;
            const iy = (point / nx) % ny;
            const iz = point / nxy;
            var local: [5]f64 = @splat(0.0);
            for (0..5) |row| {
                for (0..5) |column| {
                    local[row] += d[row * 5 + column] * forward[point * 5 + column];
                }
            }
            if (ix + 1 < nx) {
                for (0..5) |row| {
                    local[row] -= c[0] * correction[(point + 1) * 5 + row];
                }
            }
            if (iy + 1 < ny) {
                for (0..5) |row| {
                    local[row] -= c[1] * correction[(point + nx) * 5 + row];
                }
            }
            if (iz + 1 < nz) {
                for (0..5) |row| {
                    local[row] -= c[2] * correction[(point + nxy) * 5 + row];
                }
            }
            const solved = solve5(&d, local) orelse return -1;
            for (0..5) |row| {
                correction[point * 5 + row] = solved[row];
            }
        }
        for (0..count) |index| {
            x[index] += correction[index];
        }
        apply(nx, ny, nz, &d, &c, &x, &applied);
        var norm2: f64 = 0.0;
        for (0..count) |index| {
            const difference = rhs[index] - applied[index];
            norm2 += difference * difference;
        }
        const norm = @sqrt(norm2);
        if (!std.math.isFinite(norm)) return -1;
        writeF64Le(out, sweep * 8, norm);
    }
    for (0..count) |index| {
        writeF64Le(out, (sweeps + index) * 8, x[index]);
    }
    return @intCast(output_bytes);
}
