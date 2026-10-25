/*
    Copyright (C) 1996 McGill University.
    Copyright (C) 1996 McCAT System Group.
    Copyright (C) 1996 ACAPS Benchmark Administrator
                       benadmin@acaps.cs.mcgill.ca

    This program is free software; you can redistribute it and/or modify
    it provided this copyright notice is maintained.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/
const MIN_N: usize = 3;
const MAX_N: usize = 8;
const MAX_INPUT: usize = 66;
const INPUT_SCALE: f64 = 1_000_000.0;
const OUTPUT_SCALE: f64 = 1_000.0;
const QR_EPSILON: f64 = 1.0e-10;
const MAX_QR_STEPS: usize = 4096;

fn absd(value: f64) f64 { return if (value < 0.0) -value else value; }
fn givens(a: f64, b: f64) struct { s: f64, c: f64 } {
    if (b == 0.0) return .{ .s = 0.0, .c = 1.0 };
    if (absd(b) > absd(a)) {
        const t = -a / b;
        const s = 1.0 / @sqrt(1.0 + t * t);
        return .{ .s = s, .c = s * t };
    }
    const t = -b / a;
    const c = 1.0 / @sqrt(1.0 + t * t);
    return .{ .s = c * t, .c = c };
}
fn applyGivens(a: *[64]f64, n: usize, s: f64, c: f64, i: usize, j: usize, start: usize, ending: usize) void {
    for (start..ending + 1) |k| {
        const x = a.*[i * n + k]; const y = a.*[j * n + k];
        a.*[i * n + k] = c * x - s * y; a.*[j * n + k] = s * x + c * y;
    }
    for (start..ending + 1) |k| {
        const x = a.*[k * n + i]; const y = a.*[k * n + j];
        a.*[k * n + i] = c * x - s * y; a.*[k * n + j] = s * x + c * y;
    }
}
fn reduceBand(a: *[64]f64, n: usize, bandwidth: usize) void {
    var i = bandwidth;
    while (i >= 2) : (i -= 1) {
        for (0..n - i) |j| {
            const rotation = givens(a.*[j * n + j + i - 1], a.*[j * n + j + i]);
            const ending = @min(j + 2 * i, n - 1);
            applyGivens(a, n, rotation.s, rotation.c, j + i - 1, j + i, j, ending);
            var m = j + i;
            while (m < n - i) : (m += i) {
                const next = givens(a.*[(m - 1) * n + m + i - 1], a.*[(m - 1) * n + m + i]);
                const end2 = @min(m + 2 * i, n - 1);
                applyGivens(a, n, next.s, next.c, m + i - 1, m + i, m - 1, end2);
            }
        }
        if (i == 2) break;
    }
}
fn qrIterate(a: *[64]f64, n: usize) bool {
    var steps: usize = 0;
    while (true) {
        for (0..n - 1) |index| {
            if (absd(a.*[(index + 1) * n + index]) < (absd(a.*[index * n + index]) + absd(a.*[(index + 1) * n + index + 1])) * QR_EPSILON) {
                a.*[(index + 1) * n + index] = 0.0; a.*[index * n + index + 1] = 0.0;
            }
        }
        var q = n - 1;
        while (q > 0 and a.*[(q - 1) * n + q] == 0.0) : (q -= 1) {}
        if (q == 0) return true;
        steps += 1;
        if (steps > MAX_QR_STEPS) return false;
        var p = q;
        while (p > 0 and a.*[(p - 1) * n + p] != 0.0) : (p -= 1) {}
        const d = (a.*[(q - 1) * n + q - 1] - a.*[q * n + q]) / 2.0;
        const t = a.*[q * n + q - 1] * a.*[q * n + q - 1];
        const sign: f64 = if (d < 0.0) -1.0 else 1.0;
        const mu = a.*[q * n + q] - t / (d + sign * @sqrt(d * d + t));
        var x = a.*[p * n + p] - mu;
        var z = a.*[(p + 1) * n + p];
        var index = p;
        while (index < q) : (index += 1) {
            const rotation = givens(x, z);
            const l = if (index > p) index - 1 else p;
            const ending = @min(q, index + 2);
            for (l..ending + 1) |k| {
                const u = a.*[index * n + k]; const v = a.*[(index + 1) * n + k];
                a.*[index * n + k] = rotation.c * u - rotation.s * v; a.*[(index + 1) * n + k] = rotation.s * u + rotation.c * v;
            }
            for (l..ending + 1) |k| {
                const u = a.*[k * n + index]; const v = a.*[k * n + index + 1];
                a.*[k * n + index] = rotation.c * u - rotation.s * v; a.*[k * n + index + 1] = rotation.s * u + rotation.c * v;
            }
            if (index < q - 1) { x = a.*[(index + 1) * n + index]; z = a.*[(index + 2) * n + index]; }
        }
    }
}
fn project(value: f64) i32 {
    const scaled = value * OUTPUT_SCALE;
    return @intFromFloat(if (scaled >= 0.0) @floor(scaled + 0.5) else @ceil(scaled - 0.5));
}
fn before(left: f64, right: f64) bool { return absd(left) > absd(right) or (absd(left) == absd(right) and left < right); }
fn putI32Le(output: *[32]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |i| output.*[offset + i] = @truncate(bits >> @intCast(8 * i));
}

pub export fn mccat_05_eks(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (length < 2 or length > MAX_INPUT) return -1;
    const n64 = values[0]; const bw64 = values[1];
    if (n64 < MIN_N or n64 > MAX_N or bw64 < 2 or bw64 > 5 or bw64 >= n64) return -1;
    const n: usize = @intCast(n64); const bandwidth: usize = @intCast(bw64);
    if (length != 2 + n * n) return -1;
    var a = [_]f64{0.0} ** 64;
    for (0..n) |row| {
        for (0..n) |column| {
            const value = values[2 + row * n + column];
            if (value < -1_000_000 or value > 1_000_000) return -1;
            if (row > column and value != values[2 + column * n + row]) return -1;
            if ((if (row > column) row - column else column - row) > bandwidth and value != 0) return -1;
            a[row * n + column] = @as(f64, @floatFromInt(value)) / INPUT_SCALE;
        }
    }
    const required = n * 4;
    const out = output orelse return -2;
    if (capacity < required) return -2;
    reduceBand(&a, n, bandwidth);
    if (!qrIterate(&a, n)) return -1;
    var eigenvalues = [_]f64{0.0} ** 8;
    for (0..n) |index| eigenvalues[index] = a[index * n + index];
    for (1..n) |index| {
        const value = eigenvalues[index];
        var j = index;
        while (j > 0 and before(value, eigenvalues[j - 1])) : (j -= 1) eigenvalues[j] = eigenvalues[j - 1];
        eigenvalues[j] = value;
    }
    var staged = [_]u8{0} ** 32;
    for (0..n) |index| putI32Le(&staged, 4 * index, project(eigenvalues[index]));
    for (0..required) |index| out[index] = staged[index];
    return @intCast(required);
}
